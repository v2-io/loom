# Obsidian Vault Management Guide for AI Agents

This guide covers vault-specific operations, configuration management, and safety protocols for AI agents working with Obsidian vaults. For markdown syntax and formatting, see the companion [OBSIDIAN-MARKDOWN-GUIDE.md](OBSIDIAN-MARKDOWN-GUIDE.md).

## What is an Obsidian Vault?

An Obsidian vault is more than just a folder of markdown files - it's a complete knowledge management system with:

- **Configuration state** (user preferences, plugins, themes)
- **Active workspace** (open files, layout, sessions)
- **Link relationships** (bidirectional connections between notes)
- **Plugin data** (community extensions with their own data formats)
- **Search indexes** (cached for performance)

## Vault Structure and Components

### Essential Vault Structure
```
MyVault/
├── .obsidian/                    # Configuration folder (NEVER EDIT DIRECTLY)
│   ├── app.json                  # Core settings
│   ├── workspace.json            # Current workspace state
│   ├── hotkeys.json              # Keyboard shortcuts
│   ├── core-plugins.json         # Enabled core plugins
│   ├── community-plugins.json    # Enabled community plugins
│   ├── plugins/                  # Community plugin data
│   │   └── plugin-name/
│   │       ├── main.js
│   │       └── data.json
│   ├── themes/                   # Custom themes
│   └── snippets/                 # CSS customizations
├── Notes/                        # User content (example organization)
│   ├── Daily Notes/
│   └── Projects/
├── Attachments/                  # Media files
│   ├── Images/
│   ├── Documents/
│   └── Audio/
├── Templates/                    # Reusable snippets
└── Excalidraw/                   # Plugin-specific folders (if plugins installed)
```

### Configuration Files Explained

**app.json** - Core Obsidian settings:
```json
{
  "strictLineBreaks": false,
  "useMarkdownLinks": false,
  "showFrontmatter": true,
  "defaultViewMode": "preview",
  "attachmentFolderPath": "Attachments"
}
```

**workspace.json** - Active session state:
```json
{
  "main": {
    "id": "workspace-id",
    "type": "split",
    "children": [
      {
        "type": "leaf",
        "state": {
          "type": "markdown",
          "state": {
            "file": "Notes/Current Project.md",
            "mode": "source"
          }
        }
      }
    ]
  },
  "active": "leaf-id",
  "lastOpenFiles": ["Notes/Current Project.md", "Daily Notes/2024-01-15.md"]
}
```

## Vault Detection and Validation

### Primary Vault Detection
```python
def is_obsidian_vault(directory_path):
    """Check if a directory is an Obsidian vault"""
    obsidian_folder = os.path.join(directory_path, '.obsidian')
    return os.path.exists(obsidian_folder) and os.path.isdir(obsidian_folder)

def validate_vault_structure(vault_path):
    """Validate essential vault components"""
    checks = {
        'has_obsidian_folder': os.path.exists(os.path.join(vault_path, '.obsidian')),
        'has_app_json': os.path.exists(os.path.join(vault_path, '.obsidian', 'app.json')),
        'is_readable': os.access(vault_path, os.R_OK),
        'is_writable': os.access(vault_path, os.W_OK)
    }
    return checks
```

### Why Check .obsidian Folder?

**1. Vault Identification:**
- Confirms you're working with an Obsidian vault, not generic markdown
- Prevents applying Obsidian-specific formatting to wrong context
- Ensures user expects Obsidian behavior

**2. User Preference Detection:**
```python
def get_user_preferences(vault_path):
    """Read user's Obsidian preferences"""
    app_json = os.path.join(vault_path, '.obsidian', 'app.json')
    defaults = {
        'useMarkdownLinks': False,  # True = use markdown, False = use wikilinks
        'strictLineBreaks': False,
        'showFrontmatter': True,
        'attachmentFolderPath': ''
    }
    
    if os.path.exists(app_json):
        try:
            with open(app_json, 'r') as f:
                settings = json.load(f)
                defaults.update(settings)
        except (json.JSONDecodeError, PermissionError):
            pass  # Use defaults if can't read
    
    return defaults
```

**3. Plugin Detection:**
```python
def get_active_plugins(vault_path):
    """Determine which plugins are active"""
    plugins = {'core': [], 'community': []}
    
    # Core plugins
    core_plugins_file = os.path.join(vault_path, '.obsidian', 'core-plugins.json')
    if os.path.exists(core_plugins_file):
        with open(core_plugins_file, 'r') as f:
            plugins['core'] = json.load(f)
    
    # Community plugins
    community_plugins_file = os.path.join(vault_path, '.obsidian', 'community-plugins.json')
    if os.path.exists(community_plugins_file):
        with open(community_plugins_file, 'r') as f:
            plugins['community'] = json.load(f)
    
    return plugins
```

**4. Concurrent Access Safety:**
```python
def check_workspace_state(vault_path):
    """Check what files are currently open"""
    workspace_file = os.path.join(vault_path, '.obsidian', 'workspace.json')
    open_files = []
    
    if os.path.exists(workspace_file):
        try:
            with open(workspace_file, 'r') as f:
                workspace = json.load(f)
                # Extract currently open files
                open_files = workspace.get('lastOpenFiles', [])
        except (json.JSONDecodeError, PermissionError):
            pass
    
    return open_files

def is_obsidian_running():
    """Check if Obsidian application is currently running"""
    import psutil
    for proc in psutil.process_iter(['name']):
        if 'obsidian' in proc.info['name'].lower():
            return True
    return False
```

## Critical: Link Update Behavior

**⚠️ IMPORTANT FOR AI AGENTS:**
Obsidian does NOT automatically update links when files are renamed or moved programmatically. This is a critical misconception.

**What Actually Happens:**
- When Obsidian user renames a file through the UI, it offers to update links
- When AI agents rename files programmatically, **NO automatic updates occur**
- **AI must manually find and update all inbound links**

**AI Responsibility for File Operations:**
```python
def rename_file_safely(vault_path, old_path, new_path):
    """Rename file and update all inbound links"""
    # 1. Find all files that link to this file
    inbound_links = find_inbound_links(vault_path, old_path)
    
    # 2. Rename the actual file
    os.rename(old_path, new_path)
    
    # 3. Update all links in other files
    old_name = os.path.splitext(os.path.basename(old_path))[0]
    new_name = os.path.splitext(os.path.basename(new_path))[0]
    
    for linking_file in inbound_links:
        update_links_in_file(linking_file, old_name, new_name)
    
    # 4. Update canvas references
    canvas_files = find_canvas_references(vault_path, old_path)
    for canvas_file in canvas_files:
        update_canvas_references(canvas_file, old_path, new_path)

def find_inbound_links(vault_path, target_file):
    """Find all files that link to the target file"""
    inbound_links = []
    filename_without_ext = os.path.splitext(os.path.basename(target_file))[0]
    
    for root, dirs, files in os.walk(vault_path):
        if '.obsidian' in dirs:
            dirs.remove('.obsidian')
            
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                if file_path == target_file:
                    continue  # Skip the file itself
                    
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                # Check for wikilinks: [[Filename]]
                if f'[[{filename_without_ext}]]' in content:
                    inbound_links.append(file_path)
                    
                # Check for markdown links: [text](filename.md)
                if f']({os.path.basename(target_file)})' in content:
                    inbound_links.append(file_path)
                    
    return inbound_links

def update_links_in_file(file_path, old_name, new_name):
    """Update all links in a single file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update wikilinks
    content = content.replace(f'[[{old_name}]]', f'[[{new_name}]]')
    content = content.replace(f'[[{old_name}|', f'[[{new_name}|')
    content = content.replace(f'[[{old_name}#', f'[[{new_name}#')
    
    # Update markdown links
    content = content.replace(f']({old_name}.md)', f']({new_name}.md)')
    
    # Update embeds
    content = content.replace(f'![[{old_name}]]', f'![[{new_name}]]')
    content = content.replace(f'![[{old_name}|', f'![[{new_name}|')
    content = content.replace(f'![[{old_name}#', f'![[{new_name}#')
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
```

**Key Rules for AI:**
1. **Never rename files without updating inbound links**
2. **Always search entire vault for references**
3. **Update both wikilinks and markdown links**
4. **Update embeds (!) and regular links**
5. **Update canvas file references**
6. **Test link integrity after rename operations**

## File System and Path Management

### Accepted File Formats
```python
OBSIDIAN_SUPPORTED_FORMATS = {
    'text': ['.md', '.txt'],
    'images': ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.svg', '.webp'],
    'audio': ['.mp3', '.wav', '.m4a', '.3gp', '.flac', '.ogg', '.oga', '.opus'],
    'video': ['.mp4', '.webm', '.ogv', '.mov', '.mkv'],
    'documents': ['.pdf'],
    'web': ['.html'],
    'obsidian': ['.canvas', '.excalidraw']
}

def is_supported_format(file_path):
    """Check if file format is supported by Obsidian"""
    extension = os.path.splitext(file_path)[1].lower()
    for format_type, extensions in OBSIDIAN_SUPPORTED_FORMATS.items():
        if extension in extensions:
            return True
    return False
```

### Safe File Naming
```python
def sanitize_filename(filename):
    """Create Obsidian-safe filename"""
    # Characters that break Obsidian linking
    unsafe_chars = ['#', '|', '^', ':', '%', '[', ']']
    
    safe_name = filename
    for char in unsafe_chars:
        safe_name = safe_name.replace(char, '-')
    
    # Remove multiple spaces and trim
    safe_name = ' '.join(safe_name.split())
    
    return safe_name

def validate_filename(filename):
    """Check if filename is safe for Obsidian"""
    unsafe_chars = ['#', '|', '^', ':', '%', '[', ']']
    issues = []
    
    for char in unsafe_chars:
        if char in filename:
            issues.append(f"Contains unsafe character: {char}")
    
    if len(filename) > 255:
        issues.append("Filename too long (>255 characters)")
    
    if filename.startswith('.'):
        issues.append("Filename starts with dot (may be hidden)")
    
    return issues
```

### Attachment Management
```python
def get_attachment_folder(vault_path):
    """Get user's preferred attachment folder"""
    preferences = get_user_preferences(vault_path)
    attachment_path = preferences.get('attachmentFolderPath', '')
    
    if attachment_path:
        return os.path.join(vault_path, attachment_path)
    else:
        return vault_path  # Root of vault

def organize_attachment(file_path, vault_path, attachment_type=None):
    """Move attachment to appropriate folder"""
    attachment_folder = get_attachment_folder(vault_path)
    
    if attachment_type:
        # Create type-specific subfolder
        type_folder = os.path.join(attachment_folder, attachment_type.title())
        os.makedirs(type_folder, exist_ok=True)
        destination = os.path.join(type_folder, os.path.basename(file_path))
    else:
        destination = os.path.join(attachment_folder, os.path.basename(file_path))
    
    shutil.move(file_path, destination)
    return destination
```

## Canvas Integration

### Canvas File Structure
Canvas files (`.canvas`) are JSON structures that can reference markdown notes:

```json
{
  "nodes": [
    {
      "id": "unique-node-id",
      "type": "file",
      "file": "Notes/Project Overview.md",
      "x": 100,
      "y": 200,
      "width": 400,
      "height": 300,
      "color": "1"
    },
    {
      "id": "text-node-id", 
      "type": "text",
      "text": "This is a text node",
      "x": 600,
      "y": 200,
      "width": 300,
      "height": 100
    }
  ],
  "edges": [
    {
      "id": "edge-id",
      "fromNode": "unique-node-id",
      "fromSide": "right",
      "toNode": "text-node-id",
      "toSide": "left"
    }
  ]
}
```

### Canvas Considerations for AI
```python
def find_canvas_references(vault_path, note_path):
    """Find canvas files that reference a specific note"""
    canvas_files = []
    relative_note_path = os.path.relpath(note_path, vault_path)
    
    for root, dirs, files in os.walk(vault_path):
        for file in files:
            if file.endswith('.canvas'):
                canvas_path = os.path.join(root, file)
                with open(canvas_path, 'r') as f:
                    try:
                        canvas_data = json.load(f)
                        for node in canvas_data.get('nodes', []):
                            if node.get('file') == relative_note_path:
                                canvas_files.append(canvas_path)
                                break
                    except json.JSONDecodeError:
                        continue
    
    return canvas_files

def update_canvas_references(canvas_path, old_path, new_path):
    """Update canvas file references when notes are moved"""
    with open(canvas_path, 'r') as f:
        canvas_data = json.load(f)
    
    modified = False
    for node in canvas_data.get('nodes', []):
        if node.get('file') == old_path:
            node['file'] = new_path
            modified = True
    
    if modified:
        with open(canvas_path, 'w') as f:
            json.dump(canvas_data, f, indent=2)
```

## Search and Indexing

### Search Syntax Impact
Content structure affects discoverability:

```python
def build_search_index(vault_path):
    """Build searchable index of vault content"""
    index = {
        'files': {},      # filename -> path mapping
        'tags': {},       # tag -> [files] mapping  
        'properties': {}, # property -> [files] mapping
        'blocks': {},     # block-id -> file mapping
        'links': {}       # link -> [linking files] mapping
    }
    
    for root, dirs, files in os.walk(vault_path):
        if '.obsidian' in dirs:
            dirs.remove('.obsidian')  # Skip config folder
            
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, vault_path)
                
                # Index filename
                filename = os.path.splitext(file)[0]
                index['files'][filename] = relative_path
                
                # Parse file content
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                # Index properties, tags, blocks, links
                index_file_content(content, relative_path, index)
    
    return index
```

## Template Processing

### Template Variables and Expansion
```python
def expand_template_variables(content, context=None):
    """Expand Obsidian template variables"""
    from datetime import datetime
    import re
    
    if context is None:
        context = {}
    
    # Default context
    now = datetime.now()
    default_context = {
        'title': context.get('title', 'Untitled'),
        'date': now.strftime('%Y-%m-%d'),
        'time': now.strftime('%H:%M'),
        'datetime': now.strftime('%Y-%m-%dT%H:%M:%S')
    }
    default_context.update(context)
    
    # Expand variables with format strings
    def replace_variable(match):
        var_name = match.group(1)
        format_str = match.group(2) if match.group(2) else None
        
        if var_name in ['date', 'time'] and format_str:
            # Use moment.js format (would need moment.js port or mapping)
            return format_datetime(now, format_str)
        else:
            return str(default_context.get(var_name, match.group(0)))
    
    # Pattern: {{variable}} or {{variable:format}}
    pattern = r'\{\{(\w+)(?::([^}]+))?\}\}'
    result = re.sub(pattern, replace_variable, content)
    
    return result
```

## Safety Protocols and Backup

### Critical Safety Rules

**1. Never Modify .obsidian Folder**
```python
def is_config_file(file_path, vault_path):
    """Check if file is in configuration directory"""
    config_dir = os.path.join(vault_path, '.obsidian')
    return file_path.startswith(config_dir)

def safe_file_operation(file_path, vault_path, operation):
    """Perform operation only if file is not in config directory"""
    if is_config_file(file_path, vault_path):
        raise ValueError(f"Cannot modify configuration file: {file_path}")
    
    return operation()
```

**2. Backup Strategy**
```python
def create_vault_backup(vault_path, backup_path):
    """Create backup excluding configuration files"""
    def ignore_patterns(dir, files):
        ignored = []
        if dir == vault_path and '.obsidian' in files:
            ignored.append('.obsidian')  # Skip entire config folder
        return ignored
    
    shutil.copytree(vault_path, backup_path, ignore=ignore_patterns)
    return backup_path

def restore_vault_backup(backup_path, vault_path):
    """Restore vault from backup (preserving .obsidian)"""
    # Save current .obsidian folder
    obsidian_backup = os.path.join(vault_path + '_obsidian_temp')
    obsidian_original = os.path.join(vault_path, '.obsidian')
    
    if os.path.exists(obsidian_original):
        shutil.copytree(obsidian_original, obsidian_backup)
    
    # Restore files
    shutil.rmtree(vault_path)
    shutil.copytree(backup_path, vault_path)
    
    # Restore .obsidian folder
    if os.path.exists(obsidian_backup):
        if os.path.exists(obsidian_original):
            shutil.rmtree(obsidian_original)
        shutil.move(obsidian_backup, obsidian_original)
```

**3. Concurrent Access Management**
```python
def safe_vault_access(vault_path):
    """Context manager for safe vault access"""
    class VaultAccessManager:
        def __init__(self, vault_path):
            self.vault_path = vault_path
            self.was_obsidian_running = False
            
        def __enter__(self):
            self.was_obsidian_running = is_obsidian_running()
            if self.was_obsidian_running:
                print("Warning: Obsidian is running. File conflicts may occur.")
            return self
            
        def __exit__(self, exc_type, exc_val, exc_tb):
            if exc_type:
                print(f"Error during vault operation: {exc_val}")
            # Could implement file lock cleanup here
    
    return VaultAccessManager(vault_path)
```

## Vault Health and Maintenance

### Health Check System
```python
def comprehensive_vault_health_check(vault_path):
    """Perform complete vault health assessment"""
    health_report = {
        'broken_links': find_broken_links(vault_path),
        'invalid_yaml': find_invalid_yaml_files(vault_path),
        'orphaned_files': find_orphaned_files(vault_path),
        'duplicate_aliases': find_duplicate_aliases(vault_path),
        'missing_attachments': find_missing_attachments(vault_path),
        'canvas_integrity': check_canvas_integrity(vault_path),
        'plugin_data_integrity': check_plugin_data(vault_path)
    }
    
    # Calculate health score
    total_issues = sum(len(issues) for issues in health_report.values() if isinstance(issues, list))
    health_report['score'] = max(0, 100 - total_issues * 2)
    health_report['status'] = 'healthy' if health_report['score'] > 90 else 'needs_attention'
    
    return health_report

def find_broken_links(vault_path):
    """Find all broken internal links"""
    broken_links = []
    
    for root, dirs, files in os.walk(vault_path):
        if '.obsidian' in dirs:
            dirs.remove('.obsidian')
            
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                broken_links.extend(check_file_links(file_path, vault_path))
    
    return broken_links
```

## Integration Guidelines

### When NOT to Use Obsidian Features
```python
def determine_processing_mode(directory_path):
    """Determine how to process markdown files"""
    if is_obsidian_vault(directory_path):
        preferences = get_user_preferences(directory_path)
        return {
            'mode': 'obsidian',
            'use_wikilinks': not preferences.get('useMarkdownLinks', False),
            'process_properties': preferences.get('showFrontmatter', True),
            'strict_line_breaks': preferences.get('strictLineBreaks', False)
        }
    else:
        return {
            'mode': 'generic_markdown',
            'use_wikilinks': False,
            'process_properties': False,
            'strict_line_breaks': True
        }
```

### Export Compatibility
```python
def prepare_vault_for_export(vault_path, export_format='standard_markdown'):
    """Prepare vault content for external use"""
    if export_format == 'standard_markdown':
        # Convert Obsidian-specific features to standard markdown
        for md_file in get_markdown_files(vault_path):
            content = read_file(md_file)
            
            # Convert wikilinks to standard links
            content = convert_wikilinks_to_markdown(content, vault_path)
            
            # Remove Obsidian comments
            content = remove_obsidian_comments(content)
            
            # Convert callouts to standard blockquotes
            content = convert_callouts_to_blockquotes(content)
            
            write_file(md_file, content)
```

## Final Recommendations

### Vault Operation Checklist
1. **Always check for .obsidian folder first**
2. **Read user preferences from app.json**
3. **Detect active plugins that might affect content**
4. **Check workspace.json for currently open files**
5. **Create backups before bulk operations**
6. **Validate vault structure before proceeding**
7. **Monitor for Obsidian process running concurrently**
8. **Respect user's link format preferences**
9. **Update canvas references when moving files**
10. **Perform health checks after major operations**

### Error Recovery
- Always preserve .obsidian folder during recovery
- Provide rollback capability for bulk operations
- Log all vault modifications with timestamps
- Validate operations incrementally, not at the end
- Fail gracefully - don't corrupt vault state

This guide provides the foundation for safe vault management while the markdown guide handles content formatting. Together they ensure AI agents can work effectively with Obsidian's complete ecosystem.