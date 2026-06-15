#!/bin/bash

echo "=========================================="
echo "  Swimlane App - Testing Guide"
echo "=========================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_URL="http://localhost:3000"

echo -e "\n${BLUE}Starting port-forward in background...${NC}"
kubectl -n swimlane port-forward service/swimlane-app 3000:80 >/dev/null 2>&1 &
PF_PID=$!
echo "Port-forward PID: $PF_PID"

sleep 5

echo -e "\n${YELLOW}=== Test 1: Health Check ===${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ App is responding (HTTP $HTTP_CODE)${NC}"
else
    echo -e "✗ App returned HTTP $HTTP_CODE"
fi

echo -e "\n${YELLOW}=== Test 2: Database Connectivity ===${NC}"
kubectl -n swimlane logs deploy/swimlane-app --tail=20 | grep -i "mongodb\|connected\|database" || echo "Check logs manually"

echo -e "\n${YELLOW}=== Test 3: Pod Health ===${NC}"
kubectl -n swimlane get pods -l app.kubernetes.io/name=swimlane-devops-practical

echo -e "\n${YELLOW}=== Test 4: Service Endpoints ===${NC}"
kubectl -n swimlane get endpoints

echo -e "\n${GREEN}=========================================="
echo "  Manual Testing Steps"
echo "==========================================${NC}"
echo ""
echo "🌐 Open browser: ${APP_URL}"
echo ""
echo "📝 Test Scenarios:"
echo ""
echo "1. USER REGISTRATION"
echo "   - Click 'Sign up'"
echo "   - Fill: Name, Email, Password"
echo "   - Submit and verify login"
echo ""
echo "2. CREATE ARTICLE"
echo "   - Click 'New Article'"
echo "   - Title: 'Test Swimlane DevOps Lab'"
echo "   - Body: 'Testing EKS deployment with MongoDB'"
echo "   - Tags: 'devops, kubernetes, eks'"
echo "   - Click 'Publish'"
echo ""
echo "3. VERIFY PERSISTENCE"
echo "   - Refresh the page"
echo "   - Article should still be visible"
echo "   - This proves MongoDB is working"
echo ""
echo "4. ADD COMMENT"
echo "   - Open your article"
echo "   - Add a comment"
echo "   - Verify it appears"
echo ""
echo "5. TEST MULTIPLE PODS (HA)"
echo "   - Keep browser open"
echo "   - Delete one app pod: kubectl -n swimlane delete pod -l app.kubernetes.io/component=web --field-selector=status.phase=Running | head -1"
echo "   - Refresh browser - should still work (other pod serves request)"
echo ""
echo "📸 TAKE SCREENSHOT showing:"
echo "   - Article you created"
echo "   - Your username visible"
echo "   - URL bar showing localhost:3000"
echo ""
echo "💾 Save to: docs/screenshots/swimlane-app-working.png"
echo ""
echo -e "${YELLOW}=========================================="
echo "To stop port-forward:"
echo "  kill $PF_PID"
echo "==========================================${NC}"
