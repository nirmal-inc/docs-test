# docs-test
docs-testing

## GitHub Action: sync files or folders from multiple repos

This repository now includes a workflow at `.github/workflows/sync-external-content.yml` that can:

- run manually with **Actions > Sync External Content > Run workflow**
- run on a schedule using cron
- sync multiple files or folders from multiple repositories into this repository

The source mappings live in `.github/sync-sources.json`.

Example:

```json
{
  "sources": [
    {
      "name": "service-a-docs",
      "repo": "your-org/service-a",
      "ref": "main",
      "source_path": "docs",
      "destination_path": "content/service-a",
      "delete_extra_files": true
    },
    {
      "name": "service-b-guide",
      "repo": "your-org/service-b",
      "ref": "main",
      "source_path": "README.md",
      "destination_path": "content/service-b/README.md",
      "delete_extra_files": false
    }
  ]
}
```

Each source entry supports:

- `name`: unique name used for manual single-source syncs
- `repo`: source repository in `owner/repo` format
- `ref`: branch, tag, or commit SHA
- `source_path`: file or directory path inside the source repository
- `destination_path`: destination path in this repository
- `delete_extra_files`: when `true`, destination folders are cleaned to mirror the source

### Optional secret for private source repositories

Add this secret in **Settings > Secrets and variables > Actions > Secrets**:

- `SYNC_SOURCE_TOKEN`: a PAT or fine-grained token with read access to the source repository

### Manual sync

You can run the workflow manually in two ways:

- leave `source_name` empty to sync all configured sources
- set `source_name` to sync only one configured source

You can also override the config file location with `config_path` if you want to keep multiple mapping files.

### Optional repository variable

If you want the workflow to read a config file from another path, set this Actions variable:

- `SYNC_CONFIG_PATH`

If it is not set, the workflow uses `.github/sync-sources.json`.

### Scheduled sync

The workflow currently runs on this cron:

```text
0 3 * * 1
```

That means every Monday at 03:00 UTC. Change the cron in `.github/workflows/sync-external-content.yml` to whatever time you want.

### Notes

- File sync copies the source file directly to the configured destination path.
- Folder sync uses `rsync`.
- If the sync changes tracked files, the workflow commits and pushes them back to the current branch automatically.
