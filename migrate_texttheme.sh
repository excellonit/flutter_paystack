#!/bin/bash

# Improved TextTheme Migration Script for Flutter
# More precise regex patterns to avoid false positives

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Migration mappings (old -> new)
declare -A MIGRATIONS=(
    ["headline1"]="displayLarge"
    ["headline2"]="displayMedium"
    ["headline3"]="displaySmall"
    ["headline4"]="headlineLarge"
    ["headline5"]="headlineMedium"
    ["headline6"]="titleLarge"
    ["subtitle1"]="titleMedium"
    ["subtitle2"]="titleSmall"
    ["bodyText1"]="bodyLarge"
    ["bodyMedium"]="bodyMedium"
    ["caption"]="bodySmall"
    ["button"]="labelLarge"
    ["overline"]="labelSmall"
)

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# More precise pattern matching for TextTheme properties
scan_precise() {
    print_status "Scanning for deprecated TextTheme properties (precise matching)..."
    echo
    
    local found_issues=false
    
    for old_prop in "${!MIGRATIONS[@]}"; do
        # More precise regex patterns to match actual TextTheme usage
        local pattern="(textTheme\(\)|\.textTheme)\.$old_prop[^a-zA-Z0-9_]"
        local files=$(find . -name "*.dart" -type f -exec grep -l -E "$pattern" {} \;)
        
        if [ -n "$files" ]; then
            local count=$(echo "$files" | wc -l)
            echo -e "${YELLOW}Found $count file(s) using TextTheme.$old_prop${NC}"
            echo "$files" | sed 's/^/  - /'
            found_issues=true
        fi
    done
    
    if [ "$found_issues" = false ]; then
        print_status "No deprecated TextTheme properties found!"
        return 1
    fi
    
    echo
    return 0
}

preview_precise() {
    print_status "Preview of TextTheme changes:"
    echo
    
    for old_prop in "${!MIGRATIONS[@]}"; do
        local new_prop="${MIGRATIONS[$old_prop]}"
        local pattern="(textTheme\(\)|\.textTheme)\.$old_prop[^a-zA-Z0-9_]"
        local files_with_prop=$(find . -name "*.dart" -type f -exec grep -l -E "$pattern" {} \;)
        
        if [ -n "$files_with_prop" ]; then
            echo -e "${BLUE}TextTheme.$old_prop → TextTheme.$new_prop${NC}"
            echo "$files_with_prop" | while read -r file; do
                echo "  File: $file"
                grep -n -E "$pattern" "$file" | head -3 | sed 's/^/    /'
                if [ $(grep -c -E "$pattern" "$file") -gt 3 ]; then
                    echo "    ... and $(( $(grep -c -E "$pattern" "$file") - 3 )) more occurrences"
                fi
            done
            echo
        fi
    done
}

apply_precise_migrations() {
    print_status "Applying precise TextTheme migrations..."
    
    local total_changes=0
    
    for old_prop in "${!MIGRATIONS[@]}"; do
        local new_prop="${MIGRATIONS[$old_prop]}"
        local pattern="(textTheme\(\)|\.textTheme)\.$old_prop([^a-zA-Z0-9_])"
        local replacement="\1.$new_prop\2"
        
        # Find files that match the pattern
        local matching_files=$(find . -name "*.dart" -type f -exec grep -l -E "$pattern" {} \;)
        
        if [ -n "$matching_files" ]; then
            local changes=0
            echo "$matching_files" | while read -r file; do
                # Use perl for more advanced regex replacement
                if command -v perl >/dev/null 2>&1; then
                    perl -i -pe "s/$pattern/\$1.$new_prop\$2/g" "$file"
                else
                    # Fallback to sed with simpler pattern
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' "s/\\.textTheme\\.$old_prop/\\.textTheme\\.$new_prop/g" "$file"
                        sed -i '' "s/textTheme()\\.$old_prop/textTheme()\\.$new_prop/g" "$file"
                    else
                        sed -i "s/\\.textTheme\\.$old_prop/\\.textTheme\\.$new_prop/g" "$file"
                        sed -i "s/textTheme()\\.$old_prop/textTheme()\\.$new_prop/g" "$file"
                    fi
                fi
            done
            
            local file_count=$(echo "$matching_files" | wc -l)
            print_status "Migrated TextTheme.$old_prop → TextTheme.$new_prop in $file_count file(s)"
            total_changes=$((total_changes + file_count))
        fi
    done
    
    print_status "Migration completed! Files modified: $total_changes"
}

# Handle command line arguments for precise matching
case "${1:-}" in
    --scan-precise)
        scan_precise
        ;;
    --preview-precise)
        scan_precise && preview_precise
        ;;
    --migrate-precise)
        scan_precise && apply_precise_migrations
        ;;
    *)
        echo "Precise TextTheme Migration Options:"
        echo "  --scan-precise    : Scan with precise pattern matching"
        echo "  --preview-precise : Preview changes with precise matching"
        echo "  --migrate-precise : Apply precise migration"
        ;;
esac