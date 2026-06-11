#!/usr/bin/env bash
set -euo pipefail

output_path="${1:?output path is required}"

release_channel="${RELEASE_CHANNEL:?RELEASE_CHANNEL is required}"
release_name="${RELEASE_NAME:?RELEASE_NAME is required}"
release_tag="${RELEASE_TAG:?RELEASE_TAG is required}"
build_version="${BUILD_VERSION:?BUILD_VERSION is required}"
version_name="${VERSION_NAME:?VERSION_NAME is required}"
build_number="${BUILD_NUMBER:?BUILD_NUMBER is required}"
apk_name="${APK_NAME:?APK_NAME is required}"
metadata_name="${METADATA_NAME:?METADATA_NAME is required}"
notes_name="${NOTES_NAME:?NOTES_NAME is required}"
apk_sha256="${APK_SHA256:?APK_SHA256 is required}"
commit_sha="${COMMIT_SHA:?COMMIT_SHA is required}"
commit_url="${COMMIT_URL:?COMMIT_URL is required}"
repo_url="${REPO_URL:?REPO_URL is required}"
run_url="${RUN_URL:?RUN_URL is required}"
ref_name="${REF_NAME:?REF_NAME is required}"
created_at_utc="${CREATED_AT_UTC:?CREATED_AT_UTC is required}"

previous_ref=""
commit_range=""
if [[ "$release_channel" == "versioned" ]]; then
  previous_ref="$(git describe --tags --abbrev=0 "${release_tag}^" 2>/dev/null || true)"
  if [[ -n "$previous_ref" ]]; then
    commit_range="${previous_ref}..${commit_sha}"
  fi
fi

if [[ -z "$commit_range" ]]; then
  commit_range="${commit_sha}~20..${commit_sha}"
fi

mapfile -t commit_subjects < <(git log --no-merges --pretty=format:%s "$commit_range" 2>/dev/null || true)
if [[ ${#commit_subjects[@]} -eq 0 ]]; then
  mapfile -t commit_subjects < <(git log --no-merges -n 12 --pretty=format:%s "$commit_sha" 2>/dev/null || true)
fi

added_items=()
improved_items=()
fixed_items=()
internal_items=()

for subject in "${commit_subjects[@]}"; do
  normalized="$(printf '%s' "$subject" | tr '[:upper:]' '[:lower:]')"
  if [[ "$normalized" =~ ^(feat|feature|add|added)\:?\  ]] || [[ "$normalized" == add* ]]; then
    added_items+=("$subject")
  elif [[ "$normalized" =~ ^(fix|fixed|bug|hotfix)\:?\  ]] || [[ "$normalized" == fix* ]]; then
    fixed_items+=("$subject")
  elif [[ "$normalized" =~ ^(perf|refactor|improve|improved|polish|tighten|update)\:?\  ]] || [[ "$normalized" == improve* ]]; then
    improved_items+=("$subject")
  else
    internal_items+=("$subject")
  fi
done

print_section() {
  local title="$1"
  shift
  local -a items=("$@")

  if [[ ${#items[@]} -eq 0 ]]; then
    return
  fi

  printf '## %s\n\n' "$title" >> "$output_path"
  local item
  for item in "${items[@]}"; do
    printf -- '- %s\n' "$item" >> "$output_path"
  done
  printf '\n' >> "$output_path"
}

highlights=()
if [[ ${#added_items[@]} -gt 0 ]]; then
  highlights+=("${added_items[0]}")
fi
if [[ ${#improved_items[@]} -gt 0 ]]; then
  highlights+=("${improved_items[0]}")
fi
if [[ ${#fixed_items[@]} -gt 0 ]]; then
  highlights+=("${fixed_items[0]}")
fi
if [[ ${#highlights[@]} -eq 0 && ${#internal_items[@]} -gt 0 ]]; then
  highlights+=("${internal_items[0]}")
fi

{
  printf '# %s\n\n' "$release_name"

  if [[ "$release_channel" == "latest" ]]; then
    printf 'Rolling prerelease APK built from the latest `master` commit. Use this build for continuous internal QA and early device validation.\n\n'
  else
    printf 'Versioned release APK for Immich TV. This release is packaged for distribution, traceability, and reproducible rollback.\n\n'
  fi

  if [[ ${#highlights[@]} -gt 0 ]]; then
    printf '## Highlights\n\n'
    for item in "${highlights[@]}"; do
      printf -- '- %s\n' "$item"
    done
    printf '\n'
  fi
} > "$output_path"

print_section "Added" "${added_items[@]}"
print_section "Improved" "${improved_items[@]}"
print_section "Fixed" "${fixed_items[@]}"

{
  printf '## Release Assets\n\n'
  printf -- '- `%s`\n' "$apk_name"
  printf -- '- `%s.sha256`\n' "$apk_name"
  printf -- '- `%s`\n' "$metadata_name"
  printf -- '- `%s`\n\n' "$notes_name"

  printf '## Build Metadata\n\n'
  printf -- '- Release tag: `%s`\n' "$release_tag"
  printf -- '- Version: `%s`\n' "$version_name"
  printf -- '- Build number: `%s`\n' "$build_number"
  printf -- '- Build version: `%s`\n' "$build_version"
  printf -- '- Source ref: `%s`\n' "$ref_name"
  printf -- '- Commit: [`%s`](%s)\n' "${commit_sha:0:7}" "$commit_url"
  printf -- '- Created: `%s`\n' "$created_at_utc"
  if [[ -n "$previous_ref" ]]; then
    printf -- '- Changes since: `%s`\n' "$previous_ref"
  fi
  printf '\n'

  printf '## Integrity\n\n'
  printf -- '- SHA256: `%s`\n\n' "$apk_sha256"

  printf '## Installation\n\n'
  printf -- '- Download the APK asset attached to this release.\n'
  printf -- '- Enable app installs for your test device if required.\n'
  printf -- '- Keep the checksum with the APK when mirroring builds across environments.\n\n'
} >> "$output_path"

print_section "Internal" "${internal_items[@]}"

{
  printf '## Links\n\n'
  printf -- '- Repository: %s\n' "$repo_url"
  printf -- '- Workflow run: %s\n' "$run_url"
} >> "$output_path"
