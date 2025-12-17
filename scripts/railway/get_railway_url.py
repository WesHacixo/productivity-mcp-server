#!/usr/bin/env python3
"""
Get Railway service URL using Railway GraphQL API
Usage: python3 get_railway_url.py [API_TOKEN]
   Or: export RAILWAY_API='token' && python3 get_railway_url.py
"""

import os
import sys
import json
import urllib.request
import urllib.parse

PROJECT_ID = "6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5"
ENVIRONMENT_ID = "494b4e30-a755-4953-9de9-3b569e038246"

def get_api_key():
    """Get Railway API key from various sources"""
    # Command line argument
    if len(sys.argv) > 1:
        return sys.argv[1]
    
    # Environment variables
    for var_name in ["RAILWAY_API", "RAILWAY_API_KEY", "RAILWAY_TOKEN"]:
        api_key = os.getenv(var_name)
        if api_key:
            print(f"✅ Using {var_name} from environment")
            return api_key
    
    # Try macOS Keychain (account: DAE)
    # Pattern: security add-generic-password -a "DAE" -s "service-name" -w "$RAILWAY_API" -U
    # Retrieve: security find-generic-password -a "DAE" -s "service-name" -w
    if sys.platform == "darwin":
        try:
            import subprocess
            # Try common service names first
            service_names = [
                "railway-api-key",  # Most likely based on example pattern
                "railway",
                "RAILWAY_API",
                "railway-token",
            ]
            
            for service_name in service_names:
                result = subprocess.run(
                    ["security", "find-generic-password", "-a", "DAE", "-s", service_name, "-w"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                api_key = result.stdout.strip()
                if result.returncode == 0 and api_key and len(api_key) > 10:
                    print(f"✅ Found API key in keychain (account: DAE, service: {service_name})")
                    return api_key
            
            # Fallback: try with UUID service (if Railway CLI created it)
            service_uuid = "3892e3a9-d6e1-463c-9a8f-3462cd0c9e00"
            result = subprocess.run(
                ["security", "find-generic-password", "-a", "DAE", "-s", service_uuid, "-w"],
                capture_output=True,
                text=True,
                timeout=10
            )
            api_key = result.stdout.strip()
            if result.returncode == 0 and api_key and len(api_key) > 10:
                print("✅ Found API key in keychain (account: DAE, service: UUID)")
                return api_key
            
            # Last resort: try without service name (if only one entry for account)
            result = subprocess.run(
                ["security", "find-generic-password", "-a", "DAE", "-w"],
                capture_output=True,
                text=True,
                timeout=10
            )
            api_key = result.stdout.strip()
            if result.returncode == 0 and api_key and len(api_key) > 10:
                print("✅ Found API key in keychain (account: DAE, no service specified)")
                return api_key
        except Exception as e:
            pass  # Keychain access might require user interaction
    
    return None

def get_service_domains(api_key):
    """Query Railway API for service domains"""
    url = "https://backboard.railway.app/graphql/v2"
    
    query = """
    query {
      project(id: "%s") {
        services {
          id
          name
          domains {
            domain
          }
        }
      }
    }
    """ % PROJECT_ID
    
    data = json.dumps({"query": query}).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            
            if "errors" in result:
                print("❌ API Error:")
                print(json.dumps(result["errors"], indent=2))
                return None
            
            return result.get("data", {}).get("project", {}).get("services", [])
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"❌ HTTP Error {e.code}: {error_body}")
        return None

def main():
    api_key = get_api_key()
    
    if not api_key:
        print("❌ Railway API key not found!")
        print("")
        print("Usage:")
        print("  python3 get_railway_url.py [API_TOKEN]")
        print("")
        print("Or set environment variable:")
        print("  export RAILWAY_API='your-token'")
        print("  python3 get_railway_url.py")
        print("")
        print("To get your API token:")
        print("  1. Go to: https://railway.com/account/tokens")
        print("  2. Create a new token")
        print("  3. Copy it and use it as shown above")
        sys.exit(1)
    
    print("🔍 Fetching Railway service information...")
    print("")
    
    try:
        services = get_service_domains(api_key)
        
        if not services:
            print("❌ No services found")
            return
        
        print("📋 Services:")
        print("")
        
        mcp_domain = None
        
        for service in services:
            name = service.get("name", "Unknown")
            domains = service.get("domains", [])
            
            if domains:
                domain = domains[0].get("domain", "")
                print(f"  {name}: https://{domain}")
                if name == "productivity-mcp-server":
                    mcp_domain = domain
            else:
                print(f"  {name}: No domain (unexposed)")
        
        print("")
        
        if mcp_domain:
            print("✅ Your MCP Server URL:")
            print(f"   https://{mcp_domain}")
            print("")
            print("Test it:")
            print(f"   curl https://{mcp_domain}/health")
            print("")
            print("Update webapp:")
            print(f"   export MCP_SERVER_URL=https://{mcp_domain}")
        else:
            print("⚠️  'productivity-mcp-server' has no public domain")
            print("")
            print("To generate a domain:")
            print("  1. Go to Railway dashboard")
            print("  2. Click on 'productivity-mcp-server' service")
            print("  3. Click 'Generate Domain' or 'Expose Service'")
    
    except urllib.error.URLError as e:
        print(f"❌ Request failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
