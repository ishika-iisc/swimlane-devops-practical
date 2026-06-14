locals {
  app_config_name      = "swimlane-app-config"
  app_container_port   = 3000
  app_pdb_name         = "swimlane-app"
  app_service_name     = "swimlane-app"
  app_service_account  = "swimlane-app"
  mongo_config_name    = "mongodb-init"
  mongo_pdb_name       = "mongodb"
  mongo_secret_name    = "mongodb-credentials"
  mongo_service_name   = "mongodb"
  mongo_statefulset    = "mongodb"
  mongo_container_port = 27017

  common_labels = merge({
    "app.kubernetes.io/name" = var.app_name
  }, var.extra_labels)

  app_labels = merge(local.common_labels, {
    "app.kubernetes.io/component" = "web"
  })

  mongo_labels = merge(local.common_labels, {
    "app.kubernetes.io/component" = "mongodb"
  })

  mongodb_url = "mongodb://${var.mongo_app_username}:${var.mongo_app_password}@${local.mongo_service_name}:${local.mongo_container_port}/${var.mongo_app_database}?authSource=${var.mongo_app_database}"
}

resource "kubernetes_manifest" "namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name   = var.namespace
      labels = local.common_labels
    }
  }
}

resource "kubernetes_manifest" "app_service_account" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = local.app_service_account
      namespace = var.namespace
      labels    = local.app_labels
    }
    automountServiceAccountToken = false
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "app_config" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = local.app_config_name
      namespace = var.namespace
      labels    = local.app_labels
    }
    data = {
      NODE_ENV = var.node_env
      PORT     = tostring(local.app_container_port)
    }
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "mongo_secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = local.mongo_secret_name
      namespace = var.namespace
      labels    = local.common_labels
    }
    type = "Opaque"
    data = {
      MONGO_INITDB_ROOT_USERNAME = base64encode(var.mongo_root_username)
      MONGO_INITDB_ROOT_PASSWORD = base64encode(var.mongo_root_password)
      MONGO_APP_DATABASE         = base64encode(var.mongo_app_database)
      MONGO_APP_USERNAME         = base64encode(var.mongo_app_username)
      MONGO_APP_PASSWORD         = base64encode(var.mongo_app_password)
      MONGODB_URL                = base64encode(local.mongodb_url)
    }
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "mongo_init_config" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = local.mongo_config_name
      namespace = var.namespace
      labels    = local.mongo_labels
    }
    data = {
      "01-create-app-user.sh" = <<-EOT
        #!/usr/bin/env bash
        set -euo pipefail

        mongosh --quiet \
          --username "$${MONGO_INITDB_ROOT_USERNAME}" \
          --password "$${MONGO_INITDB_ROOT_PASSWORD}" \
          --authenticationDatabase admin \
          "$${MONGO_APP_DATABASE}" <<EOF
        db = db.getSiblingDB("$${MONGO_APP_DATABASE}");
        if (!db.getUser("$${MONGO_APP_USERNAME}")) {
          db.createUser({
            user: "$${MONGO_APP_USERNAME}",
            pwd: "$${MONGO_APP_PASSWORD}",
            roles: [{ role: "readWrite", db: "$${MONGO_APP_DATABASE}" }]
          });
        }
        EOF
      EOT
    }
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "mongo_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = local.mongo_service_name
      namespace = var.namespace
      labels    = local.mongo_labels
    }
    spec = {
      type     = "ClusterIP"
      selector = local.mongo_labels
      ports = [
        {
          name       = "mongodb"
          port       = local.mongo_container_port
          targetPort = "mongodb"
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "app_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = local.app_service_name
      namespace = var.namespace
      labels    = local.app_labels
    }
    spec = {
      type     = "ClusterIP"
      selector = local.app_labels
      ports = [
        {
          name       = "http"
          port       = 80
          targetPort = "http"
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "mongo_statefulset" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "StatefulSet"
    metadata = {
      name      = local.mongo_statefulset
      namespace = var.namespace
      labels    = local.mongo_labels
    }
    spec = {
      serviceName = local.mongo_service_name
      replicas    = 1
      selector = {
        matchLabels = local.mongo_labels
      }
      template = {
        metadata = {
          labels = local.mongo_labels
        }
        spec = {
          securityContext = {
            fsGroup = 999
            seccompProfile = {
              type = "RuntimeDefault"
            }
          }
          containers = [
            {
              name            = "mongodb"
              image           = var.mongo_image
              imagePullPolicy = "IfNotPresent"
              ports = [
                {
                  name          = "mongodb"
                  containerPort = local.mongo_container_port
                }
              ]
              env = [
                {
                  name = "MONGO_INITDB_ROOT_USERNAME"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGO_INITDB_ROOT_USERNAME"
                    }
                  }
                },
                {
                  name = "MONGO_INITDB_ROOT_PASSWORD"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGO_INITDB_ROOT_PASSWORD"
                    }
                  }
                },
                {
                  name = "MONGO_INITDB_DATABASE"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGO_APP_DATABASE"
                    }
                  }
                },
                {
                  name = "MONGO_APP_DATABASE"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGO_APP_DATABASE"
                    }
                  }
                },
                {
                  name = "MONGO_APP_USERNAME"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGO_APP_USERNAME"
                    }
                  }
                },
                {
                  name = "MONGO_APP_PASSWORD"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGO_APP_PASSWORD"
                    }
                  }
                }
              ]
              readinessProbe = {
                exec = {
                  command = [
                    "mongosh",
                    "--quiet",
                    "--eval",
                    "db.adminCommand({ ping: 1 }).ok"
                  ]
                }
                initialDelaySeconds = 10
                periodSeconds       = 10
                timeoutSeconds      = 5
                failureThreshold    = 6
              }
              livenessProbe = {
                exec = {
                  command = [
                    "mongosh",
                    "--quiet",
                    "--eval",
                    "db.adminCommand({ ping: 1 }).ok"
                  ]
                }
                initialDelaySeconds = 30
                periodSeconds       = 20
                timeoutSeconds      = 5
                failureThreshold    = 3
              }
              resources = {
                requests = {
                  cpu    = "100m"
                  memory = "256Mi"
                }
                limits = {
                  cpu    = "1"
                  memory = "1Gi"
                }
              }
              volumeMounts = [
                {
                  name      = "mongodb-data"
                  mountPath = "/data/db"
                },
                {
                  name      = "mongodb-init"
                  mountPath = "/docker-entrypoint-initdb.d/01-create-app-user.sh"
                  subPath   = "01-create-app-user.sh"
                  readOnly  = true
                }
              ]
            }
          ]
          volumes = [
            {
              name = "mongodb-init"
              configMap = {
                name        = local.mongo_config_name
                defaultMode = 493
              }
            }
          ]
        }
      }
      volumeClaimTemplates = [
        {
          metadata = {
            name   = "mongodb-data"
            labels = local.mongo_labels
          }
          spec = merge(
            {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.mongo_storage_size
                }
              }
            },
            var.mongo_storage_class_name == null ? {} : {
              storageClassName = var.mongo_storage_class_name
            }
          )
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.mongo_init_config,
    kubernetes_manifest.mongo_secret,
    kubernetes_manifest.mongo_service
  ]
}

resource "kubernetes_manifest" "app_deployment" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = local.app_service_name
      namespace = var.namespace
      labels    = local.app_labels
    }
    spec = {
      replicas             = var.app_replicas
      revisionHistoryLimit = 3
      selector = {
        matchLabels = local.app_labels
      }
      strategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxSurge       = 1
          maxUnavailable = 0
        }
      }
      template = {
        metadata = {
          labels = local.app_labels
        }
        spec = {
          serviceAccountName           = local.app_service_account
          automountServiceAccountToken = false
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 1001
            runAsGroup   = 1001
            fsGroup      = 1001
            seccompProfile = {
              type = "RuntimeDefault"
            }
          }
          topologySpreadConstraints = [
            {
              maxSkew           = 1
              topologyKey       = "kubernetes.io/hostname"
              whenUnsatisfiable = "ScheduleAnyway"
              labelSelector = {
                matchLabels = local.app_labels
              }
            }
          ]
          affinity = {
            podAntiAffinity = {
              preferredDuringSchedulingIgnoredDuringExecution = [
                {
                  weight = 100
                  podAffinityTerm = {
                    topologyKey = "kubernetes.io/hostname"
                    labelSelector = {
                      matchLabels = local.app_labels
                    }
                  }
                }
              ]
            }
          }
          initContainers = [
            {
              name            = "wait-for-mongodb"
              image           = var.mongo_image
              imagePullPolicy = "IfNotPresent"
              command         = ["/bin/sh", "-c"]
              args = [
                "until mongosh \"$MONGODB_URL\" --quiet --eval 'db.runCommand({ ping: 1 }).ok' | grep 1; do echo waiting for mongodb; sleep 2; done"
              ]
              env = [
                {
                  name = "MONGODB_URL"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGODB_URL"
                    }
                  }
                }
              ]
              resources = {
                requests = {
                  cpu    = "50m"
                  memory = "128Mi"
                }
                limits = {
                  cpu    = "250m"
                  memory = "256Mi"
                }
              }
              securityContext = {
                allowPrivilegeEscalation = false
                capabilities = {
                  drop = ["ALL"]
                }
              }
            }
          ]
          containers = [
            {
              name            = "app"
              image           = var.app_image
              imagePullPolicy = var.app_image_pull_policy
              ports = [
                {
                  name          = "http"
                  containerPort = local.app_container_port
                }
              ]
              envFrom = [
                {
                  configMapRef = {
                    name = local.app_config_name
                  }
                }
              ]
              env = [
                {
                  name = "MONGODB_URL"
                  valueFrom = {
                    secretKeyRef = {
                      name = local.mongo_secret_name
                      key  = "MONGODB_URL"
                    }
                  }
                }
              ]
              readinessProbe = {
                httpGet = {
                  path = "/healthz"
                  port = "http"
                }
                initialDelaySeconds = 10
                periodSeconds       = 10
                timeoutSeconds      = 3
                failureThreshold    = 6
              }
              livenessProbe = {
                httpGet = {
                  path = "/healthz"
                  port = "http"
                }
                initialDelaySeconds = 30
                periodSeconds       = 20
                timeoutSeconds      = 3
                failureThreshold    = 3
              }
              resources = {
                requests = {
                  cpu    = var.app_cpu_request
                  memory = var.app_memory_request
                }
                limits = {
                  cpu    = var.app_cpu_limit
                  memory = var.app_memory_limit
                }
              }
              securityContext = {
                allowPrivilegeEscalation = false
                readOnlyRootFilesystem   = true
                capabilities = {
                  drop = ["ALL"]
                }
              }
            }
          ]
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.app_config,
    kubernetes_manifest.app_service,
    kubernetes_manifest.app_service_account,
    kubernetes_manifest.mongo_secret,
    kubernetes_manifest.mongo_statefulset
  ]
}

resource "kubernetes_manifest" "app_hpa" {
  manifest = {
    apiVersion = "autoscaling/v2"
    kind       = "HorizontalPodAutoscaler"
    metadata = {
      name      = local.app_service_name
      namespace = var.namespace
      labels    = local.app_labels
    }
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = local.app_service_name
      }
      minReplicas = var.app_min_replicas
      maxReplicas = var.app_max_replicas
      metrics = [
        {
          type = "Resource"
          resource = {
            name = "cpu"
            target = {
              type               = "Utilization"
              averageUtilization = 70
            }
          }
        },
        {
          type = "Resource"
          resource = {
            name = "memory"
            target = {
              type               = "Utilization"
              averageUtilization = 80
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.app_deployment]
}

resource "kubernetes_manifest" "app_pdb" {
  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = local.app_pdb_name
      namespace = var.namespace
      labels    = local.app_labels
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = local.app_labels
      }
    }
  }

  depends_on = [kubernetes_manifest.app_deployment]
}

resource "kubernetes_manifest" "mongo_pdb" {
  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = local.mongo_pdb_name
      namespace = var.namespace
      labels    = local.mongo_labels
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = local.mongo_labels
      }
    }
  }

  depends_on = [kubernetes_manifest.mongo_statefulset]
}

resource "kubernetes_manifest" "app_network_policy" {
  count = var.enable_network_policy ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = local.app_service_name
      namespace = var.namespace
      labels    = local.common_labels
    }
    spec = {
      podSelector = {
        matchLabels = local.app_labels
      }
      policyTypes = ["Ingress", "Egress"]
      ingress = [
        {
          ports = [
            {
              protocol = "TCP"
              port     = local.app_container_port
            }
          ]
        }
      ]
      egress = [
        {
          to = [
            {
              podSelector = {
                matchLabels = local.mongo_labels
              }
            }
          ]
          ports = [
            {
              protocol = "TCP"
              port     = local.mongo_container_port
            }
          ]
        },
        {
          to = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "kube-system"
                }
              }
            }
          ]
          ports = [
            {
              protocol = "UDP"
              port     = 53
            },
            {
              protocol = "TCP"
              port     = 53
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.app_deployment]
}

resource "kubernetes_manifest" "mongo_network_policy" {
  count = var.enable_network_policy ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = local.mongo_service_name
      namespace = var.namespace
      labels    = local.common_labels
    }
    spec = {
      podSelector = {
        matchLabels = local.mongo_labels
      }
      policyTypes = ["Ingress"]
      ingress = [
        {
          from = [
            {
              podSelector = {
                matchLabels = local.app_labels
              }
            }
          ]
          ports = [
            {
              protocol = "TCP"
              port     = local.mongo_container_port
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.mongo_statefulset]
}

resource "kubernetes_manifest" "app_ingress" {
  count = var.enable_ingress ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = local.app_service_name
      namespace = var.namespace
      labels    = local.app_labels
      annotations = merge(
        {
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        },
        var.ingress_annotations
      )
    }
    spec = {
      ingressClassName = var.ingress_class_name
      tls = [
        {
          hosts      = [var.ingress_host]
          secretName = var.ingress_tls_secret_name
        }
      ]
      rules = [
        {
          host = var.ingress_host
          http = {
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = local.app_service_name
                    port = {
                      name = "http"
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.app_service]
}
