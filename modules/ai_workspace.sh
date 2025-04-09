#!/bin/bash
# AI Modeling Workspace Generator Module
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
LOG_FILE="$HOME/.dev-setup/logs/ai_workspace_$(date +%Y-%m-%d_%H-%M-%S).log"
touch "$LOG_FILE"

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
    exit 1
}

# Function to display help
show_help() {
    echo "AI Modeling Workspace Generator"
    echo "Usage: $(basename $0) [config_file]"
    echo ""
    echo "This module creates a structured AI/ML project with:"
    echo "  - Proper directory structure"
    echo "  - Python virtual environment with ML libraries"
    echo "  - Jupyter notebooks for exploration and development"
    echo "  - Optional sample datasets"
    echo ""
}

# Function to create the AI project
create_ai_project() {
    # Get user input
    read -p "Enter project name (e.g., sentiment-analysis): " project_name
    
    if [ -z "$project_name" ]; then
        error "Project name cannot be empty"
    fi
    
    project_dir="$PROJECTS_DIR/$project_name"
    
    # Check if project already exists
    if [ -d "$project_dir" ]; then
        read -p "Project already exists. Overwrite? (y/n) [n]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            info "Operation cancelled"
            return 1
        fi
        
        # Backup existing project before overwriting
        backup_dir="$project_dir.backup.$(date +%Y%m%d%H%M%S)"
        info "Backing up existing project to $backup_dir"
        mv "$project_dir" "$backup_dir"
    fi
    
    # Display dataset options
    echo "Select a starter dataset:"
    echo "1. None (default)"
    echo "2. MNIST (handwritten digits)"
    echo "3. CIFAR-10 (images)"
    echo "4. Iris (classification)"
    echo "5. Boston Housing (regression)"
    read -p "Enter your choice [1-5]: " dataset_choice
    
    case $dataset_choice in
        2) dataset_type="mnist" ;;
        3) dataset_type="cifar10" ;;
        4) dataset_type="iris" ;;
        5) dataset_type="boston" ;;
        *) dataset_type="none" ;;
    esac
    
    info "🧠 Creating new AI project: $project_name"
    
    # Create project directory structure
    mkdir -p "$project_dir"/{notebooks,scripts,models,data/{raw,processed,external},results/{figures,tables},docs}
    
    # Create README file
    cat > "$project_dir/README.md" << EOF
# $project_name

## Project Overview
[Brief description of the project]

## Directory Structure
- \`notebooks/\`: Jupyter notebooks for exploration and analysis
- \`scripts/\`: Python scripts for data processing and modeling
- \`models/\`: Saved model files
- \`data/\`: Data files
  - \`raw/\`: Original, immutable data
  - \`processed/\`: Cleaned and processed data
  - \`external/\`: Data from external sources
- \`results/\`: Output from models
  - \`figures/\`: Generated figures and visualizations
  - \`tables/\`: Generated tables
- \`docs/\`: Documentation

## Setup
\`\`\`bash
# Activate the environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
\`\`\`

## Dataset
$([ "$dataset_type" != "none" ] && echo "Using the $dataset_type dataset" || echo "[Description of the dataset]")

## Models
[Description of models used]

## Results
[Summary of results]
EOF

    # Verify Python is installed
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is not installed or not in PATH"
    fi

    # Create virtual environment
    info "🔧 Setting up Python virtual environment..."
    cd "$project_dir"
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        error "Failed to create virtual environment. Please install python3-venv package and try again."
    fi

    # Activate virtual environment
    source venv/bin/activate
    if [ $? -ne 0 ]; then
        error "Failed to activate virtual environment"
    fi

    # Create requirements.txt
    info "📦 Creating requirements file..."
    cat > "$project_dir/requirements.txt" << EOF
# Data processing
numpy
pandas
scikit-learn

# Visualization
matplotlib
seaborn
plotly

# Deep learning
tensorflow
torch
torchvision

# Jupyter
jupyterlab
notebook
ipywidgets

# ML libraries
xgboost
lightgbm

# Utilities
tqdm
pyyaml
EOF

    # Install basic requirements
    info "⬇️ Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt || warning "Some packages failed to install. You might need to install them manually."

    # Set up Jupyter kernel
    info "🔮 Setting up Jupyter kernel..."
    python -m ipykernel install --user --name="$project_name" --display-name="Python ($project_name)" || warning "Failed to install Jupyter kernel"

    # Create starter notebooks
    info "📓 Creating starter notebooks..."

    # Data exploration notebook
    cat > "$project_dir/notebooks/01_data_exploration.ipynb" << EOF
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 1. Data Exploration\\n",
    "\\n",
    "This notebook explores the dataset and provides initial insights."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Import libraries\\n",
    "import numpy as np\\n",
    "import pandas as pd\\n",
    "import matplotlib.pyplot as plt\\n",
    "import seaborn as sns\\n",
    "\\n",
    "# Set visualization style\\n",
    "sns.set_style('whitegrid')\\n",
    "plt.rcParams['figure.figsize'] = (12, 8)\\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 1.1 Load the Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Load data\\n",
    "# Replace with your actual data loading code\\n",
    "# df = pd.read_csv('../data/raw/your_dataset.csv')\\n",
    "\\n",
    "# Display the first few rows\\n",
    "# df.head()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python ($project_name)",
   "language": "python",
   "name": "$project_name"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Model development notebook
    cat > "$project_dir/notebooks/02_model_development.ipynb" << EOF
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 2. Model Development\\n",
    "\\n",
    "This notebook builds and evaluates different models."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Import libraries\\n",
    "import numpy as np\\n",
    "import pandas as pd\\n",
    "import matplotlib.pyplot as plt\\n",
    "import seaborn as sns\\n",
    "from sklearn.model_selection import train_test_split\\n",
    "from sklearn.metrics import accuracy_score, classification_report, confusion_matrix\\n",
    "\\n",
    "# Set visualization style\\n",
    "sns.set_style('whitegrid')\\n",
    "plt.rcParams['figure.figsize'] = (12, 8)\\n",
    "%matplotlib inline"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python ($project_name)",
   "language": "python",
   "name": "$project_name"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Create utility scripts
    info "🔧 Creating utility scripts..."

    # Create data processing script
    cat > "$project_dir/scripts/data_processing.py" << EOF
#!/usr/bin/env python3
"""
Data processing script for $project_name.
This script handles data cleaning, preprocessing, and feature engineering.
"""

import numpy as np
import pandas as pd
import os
import argparse
from sklearn.preprocessing import StandardScaler
import logging

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_data(filepath):
    """Load data from a file."""
    logger.info(f"Loading data from {filepath}")
    # Add your data loading code here
    # Example: return pd.read_csv(filepath)
    return None

def preprocess_data(df):
    """Preprocess the data."""
    logger.info("Preprocessing data")
    # Add your preprocessing code here
    # Example: handling missing values, data type conversions, etc.
    return df

def extract_features(df):
    """Extract features from the data."""
    logger.info("Extracting features")
    # Add your feature extraction code here
    return df

def save_processed_data(df, output_path):
    """Save the processed data."""
    logger.info(f"Saving processed data to {output_path}")
    # Create the directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    # Save the data
    # Example: df.to_csv(output_path, index=False)

def main():
    parser = argparse.ArgumentParser(description='Process data for $project_name')
    parser.add_argument('--input', required=True, help='Path to input data file')
    parser.add_argument('--output', required=True, help='Path to save processed data')
    args = parser.parse_args()

    # Process the data
    df = load_data(args.input)
    if df is not None:
        df = preprocess_data(df)
        df = extract_features(df)
        save_processed_data(df, args.output)
        logger.info("Data processing completed")
    else:
        logger.error("Failed to load data")

if __name__ == "__main__":
    main()
EOF

    # Make scripts executable
    chmod +x "$project_dir/scripts/data_processing.py"

    # Initialize git repository
    info "🔄 Initializing Git repository..."
    git init
    echo "venv/" > .gitignore
    echo "__pycache__/" >> .gitignore
    echo "*.pyc" >> .gitignore
    echo ".ipynb_checkpoints/" >> .gitignore
    git add .
    git commit -m "Initial project setup"

    # Download starter dataset if requested
    if [ "$dataset_type" != "none" ]; then
        info "📥 Downloading $dataset_type dataset..."
        
        case "$dataset_type" in
            mnist)
                # Create a Python script to download MNIST
                cat > "$project_dir/scripts/download_mnist.py" << EOF
from tensorflow.keras.datasets import mnist
import numpy as np
import os

print("Downloading MNIST dataset...")
(X_train, y_train), (X_test, y_test) = mnist.load_data()

# Save to numpy files in the raw data directory
os.makedirs('../data/raw', exist_ok=True)
np.save('../data/raw/X_train.npy', X_train)
np.save('../data/raw/y_train.npy', y_train)
np.save('../data/raw/X_test.npy', X_test)
np.save('../data/raw/y_test.npy', y_test)

print("MNIST dataset downloaded and saved to data/raw directory")
print(f"Training data shape: {X_train.shape}")
print(f"Test data shape: {X_test.shape}")
EOF
                python "$project_dir/scripts/download_mnist.py" || warning "Failed to download MNIST dataset"
                ;;
            iris)
                # Create a Python script to download Iris
                cat > "$project_dir/scripts/download_iris.py" << EOF
from sklearn.datasets import load_iris
import pandas as pd
import os

print("Loading Iris dataset...")
iris = load_iris()
df = pd.DataFrame(data=iris.data, columns=iris.feature_names)
df['target'] = iris.target

os.makedirs('../data/raw', exist_ok=True)
df.to_csv('../data/raw/iris.csv', index=False)

print("Iris dataset saved to data/raw/iris.csv")
print(f"Dataset shape: {df.shape}")
EOF
                python "$project_dir/scripts/download_iris.py" || warning "Failed to download Iris dataset"
                ;;
            # Add other datasets here
        esac
    fi

    # Create a script to run Jupyter Lab
    cat > "$project_dir/run_jupyter.sh" << EOF
#!/bin/bash
# Activate virtual environment and start Jupyter Lab
source venv/bin/activate
jupyter lab
EOF
    chmod +x "$project_dir/run_jupyter.sh"

    success "✅ AI project '$project_name' created successfully!"
    info "📂 Project location: $project_dir"
    echo ""
    info "To get started:"
    echo "  cd $project_dir"
    echo "  source venv/bin/activate"
    echo "  ./run_jupyter.sh"
    
    # Deactivate virtual environment
    deactivate
    
    return 0
}

# Main execution starts here
clear
echo -e "\e[1;36m========================================\e[0m"
echo -e "\e[1;36m    🧠 AI MODELING WORKSPACE GENERATOR  \e[0m"
echo -e "\e[1;36m========================================\e[0m"
echo ""

# Check if projects directory exists
if [ ! -d "$PROJECTS_DIR" ]; then
    info "Creating projects directory: $PROJECTS_DIR"
    mkdir -p "$PROJECTS_DIR"
fi

# Display menu
echo "Please select an option:"
echo "1. Create a new AI project"
echo "2. Show help"
echo "0. Exit"
echo ""
read -p "Enter your choice [1/2/0]: " choice

case $choice in
    1) create_ai_project ;;
    2) show_help ;;
    0) exit 0 ;;
    *) 
        warning "Invalid option. Please try again."
        exit 1
        ;;
esac

exit 0