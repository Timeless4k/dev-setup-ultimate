#!/bin/bash
# Academic Project Tracker Module
# Part of the DEV-SETUP framework
# License: MIT

# Get configuration file path from arguments
CONFIG_FILE="$1"

# Load configuration if provided
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found or not specified"
    exit 1
fi

# Setup logging
LOG_FILE="$HOME/.dev-setup/logs/academic_tracker_$(date +%Y-%m-%d_%H-%M-%S).log"
touch "$LOG_FILE"

# Set defaults
ACADEMIC_DIR=${ACADEMIC_DIR:-"$HOME/Academic"}
TASKS_FILE="$HOME/.dev-setup/academic/tasks.csv"

# Helper functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "\e[32m✅ $1\e[0m"
    log "[SUCCESS] $1"
}

info() {
    echo -e "\e[34mℹ️ $1\e[0m"
    log "[INFO] $1"
}

warning() {
    echo -e "\e[33m⚠️ $1\e[0m"
    log "[WARNING] $1"
}

error() {
    echo -e "\e[31m❌ $1\e[0m"
    log "[ERROR] $1"
}

# Function to detect platform - WSL, Linux, or macOS
detect_platform() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)

# Function to configure settings
configure_settings() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m   ⚙️ ACADEMIC TRACKER SETTINGS        \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    info "Current settings:"
    info "Academic directory: $ACADEMIC_DIR"
    info "Tasks file: $TASKS_FILE"
    echo ""
    
    # Ask for new academic directory
    read -p "Enter academic directory [$ACADEMIC_DIR]: " new_academic_dir
    new_academic_dir=${new_academic_dir:-$ACADEMIC_DIR}
    
    # Update config with new settings
    if [ "$new_academic_dir" != "$ACADEMIC_DIR" ]; then
        if grep -q "ACADEMIC_DIR=" "$CONFIG_FILE"; then
            sed -i "s|ACADEMIC_DIR=.*|ACADEMIC_DIR=\"$new_academic_dir\"|" "$CONFIG_FILE"
        else
            echo "ACADEMIC_DIR=\"$new_academic_dir\"" >> "$CONFIG_FILE"
        fi
        ACADEMIC_DIR="$new_academic_dir"
        success "Academic directory updated to: $ACADEMIC_DIR"
    fi
    
    # Create directories if they don't exist
    mkdir -p "$ACADEMIC_DIR"
    mkdir -p "$(dirname "$TASKS_FILE")"
    
    success "Academic Tracker configuration updated"
    return 0
}

# Function to validate date format
validate_date() {
    local date_str="$1"
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS date validation
        date -j -f "%Y-%m-%d" "$date_str" >/dev/null 2>&1
    else
        # Linux date validation
        date -d "$date_str" >/dev/null 2>&1
    fi
    
    return $?
}

# Function to calculate days until due
days_until_due() {
    local due_date="$1"
    local today=$(date +%s)
    local due
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS
        due=$(date -j -f "%Y-%m-%d" "$due_date" +%s)
    else
        # Linux
        due=$(date -d "$due_date" +%s)
    fi
    
    echo $(( (due - today) / 86400 ))
}

# Format date output
format_date() {
    local date_str="$1"
    local days=$(days_until_due "$date_str")
    local formatted_date
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS
        formatted_date=$(date -j -f "%Y-%m-%d" "$date_str" "+%Y-%m-%d")
    else
        # Linux
        formatted_date=$(date -d "$date_str" "+%Y-%m-%d")
    fi
    
    if [ $days -lt 0 ]; then
        echo -e "\e[31m$formatted_date (${days#-} days overdue)\e[0m"
    elif [ $days -eq 0 ]; then
        echo -e "\e[31m$formatted_date (Due today)\e[0m"
    elif [ $days -eq 1 ]; then
        echo -e "\e[33m$formatted_date (Due tomorrow)\e[0m"
    elif [ $days -le 7 ]; then
        echo -e "\e[33m$formatted_date (Due in $days days)\e[0m"
    else
        echo -e "\e[32m$formatted_date (Due in $days days)\e[0m"
    fi
}

# Function to initialize the tasks file
initialize_tasks_file() {
    if [ ! -f "$TASKS_FILE" ]; then
        info "Creating tasks file at $TASKS_FILE"
        echo "Name,Due Date,Description,Status,Course" > "$TASKS_FILE"
        success "Tasks file created"
    elif [ ! -s "$TASKS_FILE" ]; then
        info "Tasks file is empty, initializing with header"
        echo "Name,Due Date,Description,Status,Course" > "$TASKS_FILE"
        success "Tasks file initialized"
    elif ! grep -q "Name,Due Date,Description,Status" "$TASKS_FILE"; then
        info "Tasks file missing header, adding header"
        # Backup existing file
        cp "$TASKS_FILE" "${TASKS_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        echo "Name,Due Date,Description,Status,Course" > "${TASKS_FILE}.new"
        cat "$TASKS_FILE" >> "${TASKS_FILE}.new"
        mv "${TASKS_FILE}.new" "$TASKS_FILE"
        success "Tasks file updated with header"
    fi
    
    return 0
}

# Function to list all tasks
list_tasks() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          📋 ALL ACADEMIC TASKS          \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        info "No tasks found. Use 'Add Task' to create tasks."
        return 0
    fi
    
    echo -e "\e[36mID  | Name                    | Due Date              | Status      | Course        \e[0m"
    echo -e "\e[36m-----------------------------------------------------------------------------\e[0m"
    
    # Skip header line and process each task
    line_number=0
    while IFS=, read -r name due_date description status course || [ -n "$name" ]; do
        # Skip header
        if [ $line_number -eq 0 ] || [ "$name" = "Name" ]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Format name (truncate if too long)
        if [ ${#name} -gt 20 ]; then
            display_name="${name:0:17}..."
        else
            display_name="$name"
        fi
        
        # Format status
        if [ "$status" = "Completed" ]; then
            status_text="\e[32mCompleted\e[0m"
        else
            status_text="\e[33mPending\e[0m  "
        fi
        
        # Format course (truncate if too long)
        if [ ${#course} -gt 12 ]; then
            display_course="${course:0:9}..."
        else
            display_course="$course"
        fi
        
        # Print task
        printf "\e[36m%-3s\e[0m | %-23s | %-20s | %-10b | %-12s\n" "$line_number" "$display_name" "$(format_date "$due_date")" "$status_text" "$display_course"
        
        line_number=$((line_number + 1))
    done < "$TASKS_FILE"
    
    return 0
}

# Function to list pending tasks
list_pending() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m        📋 PENDING ACADEMIC TASKS        \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        info "No tasks found. Use 'Add Task' to create tasks."
        return 0
    fi
    
    echo -e "\e[36mID  | Name                    | Due Date              | Course        \e[0m"
    echo -e "\e[36m----------------------------------------------------------------------\e[0m"
    
    # Track if we found any pending tasks
    found_pending=false
    
    # Skip header line and process each task
    line_number=0
    while IFS=, read -r name due_date description status course || [ -n "$name" ]; do
        # Skip header
        if [ $line_number -eq 0 ] || [ "$name" = "Name" ]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Only show pending tasks
        if [ "$status" != "Completed" ]; then
            found_pending=true
            
            # Format name (truncate if too long)
            if [ ${#name} -gt 20 ]; then
                display_name="${name:0:17}..."
            else
                display_name="$name"
            fi
            
            # Format course (truncate if too long)
            if [ ${#course} -gt 12 ]; then
                display_course="${course:0:9}..."
            else
                display_course="$course"
            fi
            
            # Print task
            printf "\e[36m%-3s\e[0m | %-23s | %-20s | %-12s\n" "$line_number" "$display_name" "$(format_date "$due_date")" "$display_course"
        fi
        
        line_number=$((line_number + 1))
    done < "$TASKS_FILE"
    
    if [ "$found_pending" = false ]; then
        info "No pending tasks found. All tasks are completed."
    fi
    
    return 0
}

# Function to list tasks due this week
list_week() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      📋 TASKS DUE THIS WEEK             \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        info "No tasks found. Use 'Add Task' to create tasks."
        return 0
    fi
    
    echo -e "\e[36mID  | Name                    | Due Date              | Status      | Course        \e[0m"
    echo -e "\e[36m-----------------------------------------------------------------------------\e[0m"
    
    # Track if we found any tasks due this week
    found_week=false
    
    # Skip header line and process each task
    line_number=0
    while IFS=, read -r name due_date description status course || [ -n "$name" ]; do
        # Skip header
        if [ $line_number -eq 0 ] || [ "$name" = "Name" ]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Calculate days until due
        days=$(days_until_due "$due_date")
        
        # Show only tasks due within 7 days
        if [ $days -ge 0 ] && [ $days -lt 7 ]; then
            found_week=true
            
            # Format name (truncate if too long)
            if [ ${#name} -gt 20 ]; then
                display_name="${name:0:17}..."
            else
                display_name="$name"
            fi
            
            # Format status
            if [ "$status" = "Completed" ]; then
                status_text="\e[32mCompleted\e[0m"
            else
                status_text="\e[33mPending\e[0m  "
            fi
            
            # Format course (truncate if too long)
            if [ ${#course} -gt 12 ]; then
                display_course="${course:0:9}..."
            else
                display_course="$course"
            fi
            
            # Print task
            printf "\e[36m%-3s\e[0m | %-23s | %-20s | %-10b | %-12s\n" "$line_number" "$display_name" "$(format_date "$due_date")" "$status_text" "$display_course"
        fi
        
        line_number=$((line_number + 1))
    done < "$TASKS_FILE"
    
    if [ "$found_week" = false ]; then
        info "No tasks due this week."
    fi
    
    return 0
}

# Function to add a new task
add_task() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          ➕ ADD NEW TASK                \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    # Get task details
    read -p "Task name: " name
    
    if [ -z "$name" ]; then
        error "Task name cannot be empty"
        return 1
    fi
    
    while true; do
        read -p "Due date (YYYY-MM-DD): " due_date
        if validate_date "$due_date"; then
            break
        else
            error "Invalid date format. Please use YYYY-MM-DD."
        fi
    done
    
    read -p "Course: " course
    
    read -p "Description: " description
    
    # Replace any commas with semicolons to avoid CSV field issues
    safe_name="${name//,/;}"
    safe_description="${description//,/;}"
    safe_course="${course//,/;}"
    
    # Add task to CSV
    echo "$safe_name,$due_date,$safe_description,Pending,$safe_course" >> "$TASKS_FILE"
    
    # Create project folder
    task_dir="$ACADEMIC_DIR/$(echo "$safe_name" | tr ' ' '_')"
    mkdir -p "$task_dir"
    
    # Create README for the task
    cat > "$task_dir/README.md" << EOF
# $safe_name

**Due Date:** $due_date
**Course:** $safe_course
**Status:** Pending

## Description
$safe_description

## Tasks
- [ ] Task 1
- [ ] Task 2

## Notes
- 

## Resources
- 
EOF
    
    success "Task added successfully!"
    info "Task folder created at: $task_dir"
    
    return 0
}

# Function to view task details
view_task() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m             📄 TASK DETAILS             \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        error "No tasks found. Use 'Add Task' to create tasks."
        return 1
    fi
    
    # List pending tasks first
    list_pending
    
    # Ask for task ID
    read -p "Enter task ID to mark as complete (or 0 to cancel): " task_id
    
    if [ "$task_id" = "0" ]; then
        info "Operation cancelled"
        return 0
    fi
    
    # Validate task ID
    if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
        error "Invalid task ID. Please enter a number."
        return 1
    fi
    
    # Calculate line number (add 1 for header row)
    line_number=$((task_id + 1))
    
    # Check if line exists in file
    if [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        error "Task ID $task_id not found"
        return 1
    fi
    
    # Extract task details
    task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status course <<< "$task_line"
    
    if [ "$status" = "Completed" ]; then
        info "Task is already marked as completed"
        return 0
    fi
    
    # Update task status in CSV file
    if [ "$PLATFORM" == "macos" ]; then
        # macOS sed
        sed -i '' "${line_number}s/,Pending,/,Completed,/" "$TASKS_FILE"
    else
        # Linux sed
        sed -i "${line_number}s/,Pending,/,Completed,/" "$TASKS_FILE"
    fi
    
    # Update README in task folder
    task_dir="$ACADEMIC_DIR/$(echo "$name" | tr ' ' '_')"
    if [ -f "$task_dir/README.md" ]; then
        if [ "$PLATFORM" == "macos" ]; then
            # macOS sed
            sed -i '' "s/\*\*Status:\*\* Pending/\*\*Status:\*\* Completed/" "$task_dir/README.md"
        else
            # Linux sed
            sed -i "s/\*\*Status:\*\* Pending/\*\*Status:\*\* Completed/" "$task_dir/README.md"
        fi
    fi
    
    success "Task marked as completed!"
    
    return 0
}

# Function to edit a task
edit_task() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m             ✏️ EDIT TASK                \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        error "No tasks found. Use 'Add Task' to create tasks."
        return 1
    fi
    
    # List tasks first
    list_tasks
    
    # Ask for task ID
    read -p "Enter task ID to edit (or 0 to cancel): " task_id
    
    if [ "$task_id" = "0" ]; then
        info "Operation cancelled"
        return 0
    fi
    
    # Validate task ID
    if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
        error "Invalid task ID. Please enter a number."
        return 1
    fi
    
    # Calculate line number (add 1 for header row)
    line_number=$((task_id + 1))
    
    # Check if line exists in file
    if [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        error "Task ID $task_id not found"
        return 1
    fi
    
    # Extract task details
    task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status course <<< "$task_line"
    
    echo -e "\e[34mEditing task:\e[0m \e[36m$name\e[0m"
    echo -e "\e[33m(Leave field empty to keep current value)\e[0m"
    
    # Get new values
    read -p "Task name [$name]: " new_name
    new_name=${new_name:-$name}
    
    while true; do
        read -p "Due date [$due_date]: " new_due_date
        new_due_date=${new_due_date:-$due_date}
        
        if [ -z "$new_due_date" ] || validate_date "$new_due_date"; then
            break
        else
            error "Invalid date format. Please use YYYY-MM-DD."
        fi
    done
    
    read -p "Course [$course]: " new_course
    new_course=${new_course:-$course}
    
    read -p "Description [$description]: " new_description
    new_description=${new_description:-$description}
    
    read -p "Status (Pending/Completed) [$status]: " new_status
    new_status=${new_status:-$status}
    
    # Validate status
    if [ "$new_status" != "Pending" ] && [ "$new_status" != "Completed" ]; then
        error "Invalid status. Using '$status'."
        new_status=$status
    fi
    
    # Escape any commas to avoid CSV issues
    safe_new_name="${new_name//,/;}"
    safe_new_description="${new_description//,/;}"
    safe_new_course="${new_course//,/;}"
    
    # Update task in CSV using platform-specific sed commands
    if [ "$PLATFORM" == "macos" ]; then
        # macOS sed
        sed -i '' "${line_number}s/.*/$safe_new_name,$new_due_date,$safe_new_description,$new_status,$safe_new_course/" "$TASKS_FILE"
    else
        # Linux sed
        sed -i "${line_number}s/.*/$safe_new_name,$new_due_date,$safe_new_description,$new_status,$safe_new_course/" "$TASKS_FILE"
    fi
    
    # Handle task folder if name changed
    if [ "$name" != "$new_name" ]; then
        old_task_dir="$ACADEMIC_DIR/$(echo "$name" | tr ' ' '_')"
        new_task_dir="$ACADEMIC_DIR/$(echo "$new_name" | tr ' ' '_')"
        
        if [ -d "$old_task_dir" ]; then
            # Move folder if it exists
            mv "$old_task_dir" "$new_task_dir"
            info "Task folder renamed to: $new_task_dir"
        else
            # Create new folder
            mkdir -p "$new_task_dir"
            info "New task folder created at: $new_task_dir"
        fi
        
        # Update README
        if [ -f "$new_task_dir/README.md" ]; then
            # Update README content with platform-specific sed commands
            if [ "$PLATFORM" == "macos" ]; then
                # macOS sed
                sed -i '' "s/^# .*$/# $new_name/" "$new_task_dir/README.md"
                sed -i '' "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$new_task_dir/README.md" 
                sed -i '' "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$new_task_dir/README.md"
                sed -i '' "s/\*\*Course:\*\* .*$/\*\*Course:\*\* $new_course/" "$new_task_dir/README.md"
            else
                # Linux sed
                sed -i "s/^# .*$/# $new_name/" "$new_task_dir/README.md"
                sed -i "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$new_task_dir/README.md"
                sed -i "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$new_task_dir/README.md"
                sed -i "s/\*\*Course:\*\* .*$/\*\*Course:\*\* $new_course/" "$new_task_dir/README.md"
            fi
            
            # Update description - this is trickier with sed, so we'll use a temp file
            awk -v desc="$new_description" '
            BEGIN{replaced=0}
            /^## Description/{print; print desc; getline; replaced=1; next}
            {print}
            ' "$new_task_dir/README.md" > "$new_task_dir/README.md.tmp" 
            
            mv "$new_task_dir/README.md.tmp" "$new_task_dir/README.md"
        else
            # Create new README
            cat > "$new_task_dir/README.md" << EOF
# $new_name

**Due Date:** $new_due_date
**Course:** $new_course
**Status:** $new_status

## Description
$new_description

## Tasks
- [ ] Task 1
- [ ] Task 2

## Notes
- 

## Resources
- 
EOF
        fi
    else
        # Just update README in existing folder
        task_dir="$ACADEMIC_DIR/$(echo "$name" | tr ' ' '_')"
        if [ -f "$task_dir/README.md" ]; then
            if [ "$PLATFORM" == "macos" ]; then
                # macOS sed
                sed -i '' "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$task_dir/README.md"
                sed -i '' "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$task_dir/README.md"
                sed -i '' "s/\*\*Course:\*\* .*$/\*\*Course:\*\* $new_course/" "$task_dir/README.md"
            else
                # Linux sed
                sed -i "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$task_dir/README.md"
                sed -i "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$task_dir/README.md"
                sed -i "s/\*\*Course:\*\* .*$/\*\*Course:\*\* $new_course/" "$task_dir/README.md"
            fi
            
            # Update description
            awk -v desc="$new_description" '
            BEGIN{replaced=0}
            /^## Description/{print; print desc; getline; replaced=1; next}
            {print}
            ' "$task_dir/README.md" > "$task_dir/README.md.tmp"
            
            mv "$task_dir/README.md.tmp" "$task_dir/README.md"
        fi
    fi
    
    success "Task updated successfully!"
    
    return 0
}

# Function to delete a task
delete_task() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m             🗑️ DELETE TASK              \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        error "No tasks found. Use 'Add Task' to create tasks."
        return 1
    fi
    
    # List tasks first
    list_tasks
    
    # Ask for task ID
    read -p "Enter task ID to delete (or 0 to cancel): " task_id
    
    if [ "$task_id" = "0" ]; then
        info "Operation cancelled"
        return 0
    fi
    
    # Validate task ID
    if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
        error "Invalid task ID. Please enter a number."
        return 1
    fi
    
    # Calculate line number (add 1 for header row)
    line_number=$((task_id + 1))
    
    # Check if line exists in file
    if [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        error "Task ID $task_id not found"
        return 1
    fi
    
    # Extract task details before deleting
    task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status course <<< "$task_line"
    
    # Confirm deletion
    read -p "Are you sure you want to delete task '$name'? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Task deletion cancelled"
        return 0
    fi
    
    # Delete task from CSV using platform-specific sed commands
    if [ "$PLATFORM" == "macos" ]; then
        # macOS sed
        sed -i '' "${line_number}d" "$TASKS_FILE"
    else
        # Linux sed
        sed -i "${line_number}d" "$TASKS_FILE"
    fi
    
    # Ask about task folder
    task_dir="$ACADEMIC_DIR/$(echo "$name" | tr ' ' '_')"
    if [ -d "$task_dir" ]; then
        read -p "Do you want to delete the task folder as well? (y/n): " delete_folder
        if [[ "$delete_folder" =~ ^[Yy]$ ]]; then
            rm -rf "$task_dir"
            success "Task folder deleted"
        else
            info "Task folder kept at: $task_dir"
        fi
    fi
    
    success "Task deleted successfully!"
    
    return 0
}

# Function to create a LaTeX template
create_latex_template() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m        📝 CREATE LATEX TEMPLATE         \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if latex is installed
    if ! command -v pdflatex &> /dev/null; then
        warning "LaTeX (pdflatex) is not installed."
        read -p "Do you want to install LaTeX? (y/n): " install_latex
        
        if [[ "$install_latex" =~ ^[Yy]$ ]]; then
            if [ "$PLATFORM" == "macos" ]; then
                if command -v brew &> /dev/null; then
                    info "Installing MacTeX using Homebrew..."
                    brew install --cask mactex
                else
                    info "Please install MacTeX manually from: https://www.tug.org/mactex/"
                    info "Or install Homebrew and then run: brew install --cask mactex"
                    read -p "Press Enter to continue..."
                    return 1
                fi
            else
                info "Installing LaTeX..."
                sudo apt update
                sudo apt install -y texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended
            fi
            
            if ! command -v pdflatex &> /dev/null; then
                error "Failed to install LaTeX. Please install it manually."
                return 1
            else
                success "LaTeX installed successfully"
            fi
        else
            warning "LaTeX template creation requires LaTeX to be installed."
            read -p "Press Enter to continue..."
            return 1
        fi
    fi
    
    # First list tasks to choose from
    list_pending
    
    # Ask if user wants to create a template for an existing task or a new one
    read -p "Create template for (e)xisting task or (n)ew template? (e/n): " template_choice
    
    task_dir=""
    template_name=""
    
    if [[ "$template_choice" =~ ^[Ee]$ ]]; then
        # Choose existing task
        read -p "Enter task ID for the template (or 0 to cancel): " task_id
        
        if [ "$task_id" = "0" ]; then
            info "Operation cancelled"
            return 0
        fi
        
        # Validate task ID
        if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
            error "Invalid task ID. Please enter a number."
            return 1
        fi
        
        # Calculate line number (add 1 for header row)
        line_number=$((task_id + 1))
        
        # Check if line exists in file
        if [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
            error "Task ID $task_id not found"
            return 1
        fi
        
        # Extract task details
        task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
        IFS=, read -r name due_date description status course <<< "$task_line"
        
        task_dir="$ACADEMIC_DIR/$(echo "$name" | tr ' ' '_')"
        if [ ! -d "$task_dir" ]; then
            mkdir -p "$task_dir"
            info "Created task directory: $task_dir"
        fi
        
        template_name="$name"
        
    else
        # Create new standalone template
        read -p "Enter template name: " template_name
        
        if [ -z "$template_name" ]; then
            error "Template name cannot be empty"
            return 1
        fi
        
        task_dir="$ACADEMIC_DIR/LaTeX_Templates"
        if [ ! -d "$task_dir" ]; then
            mkdir -p "$task_dir"
            info "Created LaTeX templates directory: $task_dir"
        fi
    fi
    
    # Choose template type
    echo "Select template type:"
    echo "1. Assignment/Homework"
    echo "2. Research Paper"
    echo "3. Lab Report"
    echo "4. Essay"
    echo "5. Presentation (Beamer)"
    echo "0. Cancel"
    echo ""
    read -p "Enter your choice [0-5]: " type_choice
    
    if [ "$type_choice" = "0" ]; then
        info "Operation cancelled"
        return 0
    fi
    
    # Create subdirectory for the specific template
    template_dir="$task_dir/latex"
    mkdir -p "$template_dir"
    
    # Get author name from configuration or prompt
    author_name="${USER_NAME:-$USER}"
    read -p "Author name [$author_name]: " input_author
    author_name=${input_author:-$author_name}
    
    # Create the template file
    case $type_choice in
        1) # Assignment/Homework
            template_file="$template_dir/assignment.tex"
            
            cat > "$template_file" << EOF
\\documentclass[12pt,letterpaper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[margin=1in]{geometry}
\\usepackage{amsmath,amssymb,amsfonts}
\\usepackage{graphicx}
\\usepackage{enumitem}
\\usepackage{hyperref}
\\usepackage{fancyhdr}

% Custom header and footer
\\pagestyle{fancy}
\\fancyhf{}
\\lhead{$course}
\\rhead{$author_name}
\\cfoot{\\thepage}

\\title{$template_name}
\\author{$author_name}
\\date{\\today}

\\begin{document}

\\maketitle

\\section*{Problem 1}
Your solution here.

\\section*{Problem 2}
Your solution here.

\\section*{Problem 3}
Your solution here.

\\end{document}
EOF
            ;;
            
        2) # Research Paper
            template_file="$template_dir/research_paper.tex"
            
            cat > "$template_file" << EOF
\\documentclass[12pt,letterpaper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[margin=1in]{geometry}
\\usepackage{amsmath,amssymb,amsfonts}
\\usepackage{graphicx}
\\usepackage{hyperref}
\\usepackage{natbib}
\\usepackage{fancyhdr}

% Custom header and footer
\\pagestyle{fancy}
\\fancyhf{}
\\lhead{Research Paper}
\\rhead{$author_name}
\\cfoot{\\thepage}

\\title{$template_name}
\\author{$author_name}
\\date{\\today}

\\begin{document}

\\maketitle

\\begin{abstract}
This is the abstract of your research paper. It should be a brief summary of the paper's purpose, methods, findings, and conclusions.
\\end{abstract}

\\section{Introduction}
Your introduction here.

\\section{Background}
Background information and literature review.

\\section{Methodology}
Research methodology and approach.

\\section{Results}
Research findings and results.

\\section{Discussion}
Analysis and discussion of results.

\\section{Conclusion}
Summary and conclusions.

\\bibliographystyle{plainnat}
\\bibliography{references}

\\end{document}
EOF
            
            # Create a references.bib file
            cat > "$template_dir/references.bib" << EOF
@book{example,
  title={Example Book Title},
  author={Author, A.},
  year={2024},
  publisher={Publisher Name}
}

@article{examplearticle,
  title={Example Article Title},
  author={Author, B. and Author, C.},
  journal={Journal Name},
  volume={10},
  number={2},
  pages={123--456},
  year={2023},
  publisher={Publisher Name}
}
EOF
            ;;
            
        3) # Lab Report
            template_file="$template_dir/lab_report.tex"
            
            cat > "$template_file" << EOF
\\documentclass[12pt,letterpaper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[margin=1in]{geometry}
\\usepackage{amsmath,amssymb,amsfonts}
\\usepackage{graphicx}
\\usepackage{hyperref}
\\usepackage{siunitx}
\\usepackage{fancyhdr}

% Custom header and footer
\\pagestyle{fancy}
\\fancyhf{}
\\lhead{Lab Report}
\\rhead{$author_name}
\\cfoot{\\thepage}

\\title{$template_name\\\\Lab Report}
\\author{$author_name}
\\date{\\today}

\\begin{document}

\\maketitle

\\section{Objective}
State the objective(s) of the lab experiment.

\\section{Introduction}
Brief introduction to the lab experiment and relevant theory.

\\section{Materials and Methods}
List of materials used and detailed methodology.

\\section{Results}
Experimental results, data tables, and graphs.

\\section{Analysis}
Analysis of experimental results.

\\section{Discussion}
Discussion of findings, sources of error, and comparison with expectations.

\\section{Conclusion}
Summary of findings and conclusions.

\\section{References}
List of references used.

\\end{document}
EOF
            ;;
            
        4) # Essay
            template_file="$template_dir/essay.tex"
            
            cat > "$template_file" << EOF
\\documentclass[12pt,letterpaper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[margin=1in]{geometry}
\\usepackage{graphicx}
\\usepackage{hyperref}
\\usepackage{fancyhdr}

% Custom header and footer
\\pagestyle{fancy}
\\fancyhf{}
\\lhead{Essay}
\\rhead{$author_name}
\\cfoot{\\thepage}

\\title{$template_name}
\\author{$author_name}
\\date{\\today}

\\begin{document}

\\maketitle

\\section{Introduction}
Your introduction here.

\\section{Main Body}
Your main body text here. You can divide this into multiple sections as needed.

\\subsection{Subtopic 1}
Discussion of first subtopic.

\\subsection{Subtopic 2}
Discussion of second subtopic.

\\subsection{Subtopic 3}
Discussion of third subtopic.

\\section{Conclusion}
Your conclusion here.

\\section{References}
Your references here.

\\end{document}
EOF
            ;;
            
        5) # Presentation (Beamer)
            template_file="$template_dir/presentation.tex"
            
            cat > "$template_file" << EOF
\\documentclass{beamer}
\\usetheme{Madrid}
\\usecolortheme{default}
\\usepackage[utf8]{inputenc}
\\usepackage{graphicx}
\\usepackage{hyperref}

\\title{$template_name}
\\author{$author_name}
\\institute{Your University}
\\date{\\today}

\\begin{document}

\\frame{\\titlepage}

\\begin{frame}
\\frametitle{Outline}
\\tableofcontents
\\end{frame}

\\section{Introduction}
\\begin{frame}
\\frametitle{Introduction}
\\begin{itemize}
    \\item First point
    \\item Second point
    \\item Third point
\\end{itemize}
\\end{frame}

\\section{Main Content}
\\begin{frame}
\\frametitle{Main Content - Part 1}
Content for part 1
\\end{frame}

\\begin{frame}
\\frametitle{Main Content - Part 2}
Content for part 2
\\end{frame}

\\section{Conclusion}
\\begin{frame}
\\frametitle{Conclusion}
\\begin{itemize}
    \\item Summary point 1
    \\item Summary point 2
    \\item Summary point 3
\\end{itemize}
\\end{frame}

\\begin{frame}
\\frametitle{Thank You}
Thank you for your attention!

Questions?
\\end{frame}

\\end{document}
EOF
            ;;
        *)
            error "Invalid choice"
            return 1
            ;;
    esac
    
    # Create a compile script
    compile_script="$template_dir/compile.sh"
    
    cat > "$compile_script" << EOF
#!/bin/bash
# Simple script to compile LaTeX document

# Get the directory of this script
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd "\$SCRIPT_DIR"

# Get the base name of the tex file
TEX_FILE="$(basename "$template_file")"
BASE_NAME="\${TEX_FILE%.tex}"

# Compile the document
pdflatex "\$TEX_FILE"

# If it's a research paper, also process bibliography
if [[ "\$TEX_FILE" == *research_paper* ]]; then
    bibtex "\$BASE_NAME"
    pdflatex "\$TEX_FILE"
    pdflatex "\$TEX_FILE"
fi

# Open the PDF if possible
if command -v xdg-open &> /dev/null; then
    xdg-open "\$BASE_NAME.pdf"
elif command -v open &> /dev/null; then
    open "\$BASE_NAME.pdf"
elif command -v cmd.exe &> /dev/null; then
    cmd.exe /c start "\$BASE_NAME.pdf"
else
    echo "PDF created: \$BASE_NAME.pdf"
    echo "Please open it manually"
fi
EOF
    
    chmod +x "$compile_script"
    
    success "LaTeX template created at: $template_file"
    info "To compile the document, run: $compile_script"
    
    # Ask if user wants to compile the document now
    read -p "Do you want to compile the document now? (y/n) [y]: " compile_now
    compile_now=${compile_now:-"y"}
    
    if [[ "$compile_now" =~ ^[Yy]$ ]]; then
        # Change to the directory and compile
        cd "$template_dir"
        ./compile.sh
    fi
    
    return 0
}

# Main menu function
show_tracker_menu() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      📚 ACADEMIC PROJECT TRACKER       \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    echo "Please select an option:"
    echo "1. List all tasks"
    echo "2. List pending tasks"
    echo "3. List tasks due this week"
    echo "4. Add new task"
    echo "5. View task details"
    echo "6. Mark task as complete"
    echo "7. Edit task"
    echo "8. Delete task"
    echo "9. Create LaTeX template"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice [0-9]: " menu_choice
    
    case $menu_choice in
        1) list_tasks ;;
        2) list_pending ;;
        3) list_week ;;
        4) add_task ;;
        5) view_task ;;
        6) complete_task ;;
        7) edit_task ;;
        8) delete_task ;;
        9) create_latex_template ;;
        0) exit 0 ;;
        *)
            warning "Invalid option. Please try again."
            show_tracker_menu
            ;;
    esac
    
    # Return to menu after function completes
    read -p "Press Enter to return to the main menu..."
    show_tracker_menu
}

# Main execution starts here
# First make sure directories exist
mkdir -p "$ACADEMIC_DIR"
mkdir -p "$(dirname "$TASKS_FILE")"

# Initialize tasks file
initialize_tasks_file

# Show the main menu
show_tracker_menu
    
    # List tasks first
    list_tasks
    
    # Ask for task ID
    read -p "Enter task ID to view (or 0 to cancel): " task_id
    
    if [ "$task_id" = "0" ]; then
        info "Operation cancelled"
        return 0
    fi
    
    # Validate task ID
    if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
        error "Invalid task ID. Please enter a number."
        return 1
    fi
    
    # Calculate line number (add 1 for header row)
    line_number=$((task_id + 1))
    
    # Check if line exists in file
    if [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        error "Task ID $task_id not found"
        return 1
    fi
    
    # Extract task details
    task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status course <<< "$task_line"
    
    # Calculate days until due
    days=$(days_until_due "$due_date")
    
    # Display task details
    echo -e "\e[34m=== Task Details ===\e[0m"
    echo -e "\e[36mName:\e[0m        $name"
    echo -e "\e[36mDue Date:\e[0m    $(format_date "$due_date")"
    echo -e "\e[36mCourse:\e[0m      $course"
    echo -e "\e[36mDescription:\e[0m $description"
    
    if [ "$status" = "Completed" ]; then
        echo -e "\e[36mStatus:\e[0m      \e[32mCompleted\e[0m"
    else
        echo -e "\e[36mStatus:\e[0m      \e[33mPending\e[0m"
    fi
    
    # Check if task folder exists
    task_dir="$ACADEMIC_DIR/$(echo "$name" | tr ' ' '_')"
    if [ -d "$task_dir" ]; then
        echo -e "\e[36mFolder:\e[0m      $task_dir"
        
        # Check for files in the task folder
        file_count=$(find "$task_dir" -type f | wc -l)
        if [ $file_count -gt 1 ]; then  # More than just README.md
            echo -e "\e[36mFiles:\e[0m       $(($file_count - 1)) files in folder (excluding README)"
            echo ""
            echo -e "\e[34mFiles in task folder:\e[0m"
            find "$task_dir" -type f -not -name "README.md" | while read -r file; do
                echo -e "- \e[36m$(basename "$file")\e[0m ($(du -h "$file" | cut -f1))"
            done
        else
            echo -e "\e[36mFiles:\e[0m       No additional files in folder"
        fi
    else
        echo -e "\e[36mFolder:\e[0m      Not created yet"
    fi
    
    return 0
}

# Function to mark a task as complete
complete_task() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m           ✅ COMPLETE TASK              \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Initialize tasks file if it doesn't exist
    initialize_tasks_file
    
    if [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        error "No tasks found. Use 'Add Task' to create tasks."
        return 1
    fi
    