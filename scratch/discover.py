#!/usr/bin/env python3
import os
import re
import json
import subprocess
import urllib.request
from urllib.error import URLError

def clean_version(version_str, current):
    if not version_str:
        return None
    version_str = version_str.strip()
    # If the response has multiple lines, take the first non-empty line
    lines = [line.strip() for line in version_str.splitlines() if line.strip()]
    if lines:
        version_str = lines[0]
    
    # Strip any trailing dot or punctuation
    version_str = version_str.rstrip('.')
    
    # Specific prefix handling
    if version_str.startswith("rust-v"):
        version_str = version_str[len("rust-v"):]
    elif version_str.startswith("apps_v"):
        version_str = version_str[len("apps_v"):]
    elif version_str.startswith("v") and not current.startswith("v"):
        version_str = version_str[1:]
    elif not version_str.startswith("v") and current.startswith("v"):
        version_str = "v" + version_str
        
    return version_str

def get_latest_github(owner, repo, tag_prefix=""):
    try:
        # Use gh cli to avoid rate limits
        cmd = ["gh", "api", f"repos/{owner}/{repo}/releases/latest", "--jq", ".tag_name"]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            tag = res.stdout.strip()
            if tag_prefix and tag.startswith(tag_prefix):
                return tag[len(tag_prefix):]
            return tag
    except Exception as e:
        print(f"Error checking GitHub via gh for {owner}/{repo}: {e}")
    
    # Fallback to public api without auth
    try:
        url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode('utf-8'))
            tag = data.get('tag_name', '')
            if tag_prefix and tag.startswith(tag_prefix):
                return tag[len(tag_prefix):]
            return tag
    except Exception as e:
        print(f"Error checking GitHub API for {owner}/{repo}: {e}")
    return None

def get_latest_npm(package_name):
    try:
        url = f"https://registry.npmjs.org/{package_name}/latest"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data.get('version', '')
    except Exception as e:
        print(f"Error checking NPM for {package_name}: {e}")
    return None

def get_latest_pypi(package_name):
    try:
        url = f"https://pypi.org/pypi/{package_name}/json"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data.get('info', {}).get('version', '')
    except Exception as e:
        print(f"Error checking PyPI for {package_name}: {e}")
    return None

def query_custom_url(url, current_version):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        
        # 1. Go version
        if "go.dev/VERSION?m=text" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                content = response.read().decode('utf-8').strip()
                lines = [l.strip() for l in content.splitlines() if l.strip()]
                if lines:
                    val = lines[0]
                    if val.startswith("go"):
                        return val[2:]
                    return val
                
        # 2. Claude code releases
        if "claude-code-dist" in url and "latest" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                content = response.read().decode('utf-8').strip()
                try:
                    data = json.loads(content)
                    return data.get('version', '') or data.get('tag', '')
                except json.JSONDecodeError:
                    # It's plain text e.g. "2.1.150"
                    return content

        # 3. Cursor latest (needs curl -I or similar redirect follow)
        if "cursor.sh/updates" in url or "cursor" in url:
            cmd = ["curl", "-sI", "-H", "User-Agent: Mozilla/5.0", "https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest"]
            res = subprocess.run(cmd, capture_output=True, text=True)
            for line in res.stdout.splitlines():
                if line.lower().startswith("location:"):
                    match = re.search(r'cursor-([0-9.]+)\.x86_64', line)
                    if match:
                        return match.group(1)
                    match = re.search(r'cursor-([0-9.]+)', line)
                    if match:
                        return match.group(1)
                    match = re.search(r'/([0-9]+\.[0-9]+\.[0-9]+)/', line)
                    if match:
                        return match.group(1)
                    
        # 4. Encore releases API
        if "encore.dev/api/releases" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                data = json.loads(response.read().decode('utf-8'))
                if isinstance(data, dict) and "latest" in data:
                    return data["latest"].replace("v", "")
                if isinstance(data, dict) and "current" in data:
                    return data["current"].replace("v", "")
                if isinstance(data, list) and len(data) > 0:
                    return data[0].get("version", "").replace("v", "")

        # 5. AWS CLI changelog
        if "aws-cli/v2/CHANGELOG.rst" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                content = response.read().decode('utf-8')
                match = re.search(r'([2-9]\.[0-9]+\.[0-9]+)', content)
                if match:
                    return match.group(1)

        # 6. SoapUI releases
        if "soapui.org/downloads/latest-release/" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                html = response.read().decode('utf-8')
                match = re.search(r'SoapUI\s+([0-9.]+)', html, re.IGNORECASE)
                if match:
                    return match.group(1)

        # 7. Antigravity CLI updater
        if "antigravity-cli-auto-updater" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                data = json.loads(response.read().decode('utf-8'))
                return data.get('version', '')

        # 8. Slack release notes rss
        if "slack.com/release-notes/linux/rss" in url:
            with urllib.request.urlopen(req, timeout=5) as response:
                html = response.read().decode('utf-8')
                # Find all Slack versions
                matches = re.findall(r'Slack\s+([0-9]+\.[0-9]+\.[0-9]+)', html)
                # Filter out those that are smaller than current if we can, or just take the maximum semver
                if matches:
                    # Let's sort them semver style or just return the first one if it's newer, or max
                    # A simple key to sort semver: tuple of ints
                    def semver_key(v):
                        try:
                            return [int(x) for x in v.split('.')]
                        except ValueError:
                            return [0, 0, 0]
                    best = max(matches, key=semver_key)
                    return best

    except Exception as e:
        print(f"Error checking custom URL {url}: {e}")
    return None

def parse_makefile(filepath):
    results = []
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        line = line.strip()
        # Look for variable := value
        match = re.match(r'^([a-zA-Z_0-9]+)\s*:=\s*([^\s#]+)', line)
        if match:
            var_name = match.group(1)
            var_val = match.group(2)
            
            # Check if this is exactly 'version' or ends with '_version'
            is_version_var = (var_name.lower() == "version") or var_name.lower().endswith("_version")
            if is_version_var:
                # Look upwards for the discovery comment
                discovery_url = None
                for j in range(i - 1, max(-1, i - 5), -1):
                    prev_line = lines[j].strip()
                    if prev_line.startswith("# Discovery:"):
                        discovery_url = prev_line.replace("# Discovery:", "").strip()
                        break
                    elif prev_line.startswith("#") and "Discovery:" in prev_line:
                        discovery_url = prev_line[prev_line.find("Discovery:") + len("Discovery:"):].strip()
                        break
                
                results.append({
                    "file": filepath,
                    "variable": var_name,
                    "current": var_val,
                    "discovery_url": discovery_url,
                    "line_no": i + 1
                })
    return results

def is_greater(v_new, v_curr):
    # Basic semver comparison
    def parse_v(v):
        # strip 'v' or 'b'
        v_clean = v.lstrip('v')
        if v_clean.startswith('b'): # llama version b9330 vs b9305
            v_clean = v_clean[1:]
        # Extract numbers
        parts = re.split(r'[-.]', v_clean)
        res = []
        for p in parts:
            try:
                res.append(int(p))
            except ValueError:
                res.append(p)
        return res
    
    try:
        p_new = parse_v(v_new)
        p_curr = parse_v(v_curr)
        return p_new > p_curr
    except Exception:
        return v_new != v_curr

def main():
    root_dir = "/home/odsod/Code/github.com/odsod/machine"
    makefiles = []
    for root, dirs, files in os.walk(root_dir):
        if any(ignored in root for ignored in [".git", ".jj", ".agents", "scratch"]):
            continue
        for file in files:
            if file == "Makefile":
                makefiles.append(os.path.join(root, file))
                
    all_vars = []
    for mf in makefiles:
        all_vars.extend(parse_makefile(mf))
        
    print(f"Found {len(all_vars)} version variables across {len(makefiles)} Makefiles.")
    
    updates = []
    for item in all_vars:
        file_rel = os.path.relpath(item["file"], root_dir)
        var = item["variable"]
        curr = item["current"]
        url = item["discovery_url"]
        
        if var == "node_major":
            print(f"[-] Skipping {file_rel} ({var}={curr}) - node_major is managed by Fedora LTS stream.")
            continue
            
        if not url:
            print(f"[!] Warning: No discovery URL for {file_rel} ({var}={curr})")
            continue
            
        print(f"[*] Checking {file_rel} -> {var} (current: {curr})...")
        latest = None
        
        github_match = re.search(r'github\.com/([^/]+)/([^/]+)/releases/latest', url)
        github_general_match = re.search(r'github\.com/([^/]+)/([^/]+)/releases', url)
        github_api_match = re.search(r'api\.github\.com/repos/([^/]+)/([^/]+)/releases/latest', url)
        
        if github_match:
            owner, repo = github_match.groups()
            latest = get_latest_github(owner, repo)
        elif github_api_match:
            owner, repo = github_api_match.groups()
            latest = get_latest_github(owner, repo)
        elif github_general_match:
            owner, repo = github_general_match.groups()
            prefix = ""
            if "gopls" in var:
                prefix = "gopls/v"
            latest = get_latest_github(owner, repo, tag_prefix=prefix)
        elif "registry.npmjs.org" in url:
            pkg = url.split("registry.npmjs.org/")[1].split("/latest")[0]
            latest = get_latest_npm(pkg)
        elif "npmjs.com/package" in url:
            pkg = url.split("npmjs.com/package/")[1].split("?")[0].strip()
            latest = get_latest_npm(pkg)
        elif "pypi.org/project" in url:
            pkg = url.split("pypi.org/project/")[1].strip("/ ")
            latest = get_latest_pypi(pkg)
        elif "pypi.org/pypi" in url:
            pkg = url.split("pypi.org/pypi/")[1].split("/")[0]
            latest = get_latest_pypi(pkg)
        else:
            latest = query_custom_url(url, curr)
            
        latest = clean_version(latest, curr)
        
        if latest:
            is_new = is_greater(latest, curr)
            item["latest"] = latest
            item["is_new"] = is_new
            updates.append(item)
            if is_new:
                print(f"  [+] NEW VERSION FOUND: {curr} -> {latest}")
            else:
                print(f"  [=] Up to date: {curr}")
        else:
            print(f"  [x] Failed to retrieve latest version.")
            item["latest"] = "FAILED"
            item["is_new"] = False
            updates.append(item)
            
    report_path = "/home/odsod/Code/github.com/odsod/machine/scratch/version_report.json"
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(updates, f, indent=2)
    print(f"\nSaved report to {report_path}")

if __name__ == "__main__":
    main()
