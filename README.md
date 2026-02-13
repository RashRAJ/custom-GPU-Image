# HashiCorp Packer

This repository contains Packer templates for building machine images across multiple cloud providers.

## Overview

Packer automates the creation of machine images for multiple platforms from a single source configuration. This project includes templates for AWS and Google Cloud Platform.

## Prerequisites

- [Packer](https://www.packer.io/downloads) installed (version 1.7.0 or later recommended)
- Cloud provider credentials configured:
  - **AWS**: AWS credentials via environment variables, shared credentials file, or IAM role
  - **GCP**: Google Cloud credentials via service account key or Application Default Credentials

## Plugin Documentation

- [AWS Plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon)
- [Google Cloud Plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/googlecompute)

## Usage

Follow these steps to build your images:

### 1. Format Templates
```bash
packer fmt .
```
Formats all Packer template files in the directory to canonical style.

### 2. Initialize Plugins
```bash
packer init .
```
Downloads and installs the required plugins specified in your templates.

### 3. Validate Configuration
```bash
packer validate .
```
Validates the syntax and configuration of your templates.

To validate with a variables file:
```bash
packer validate --var-file=example.pkrvars.hcl .
```

### 4. Build Images
```bash
packer build .
```
Builds the machine images according to your template specifications.

To build with a variables file:
```bash
packer build --var-file=example.pkrvars.hcl .
```

## Managing Images

### GCP Image Management

List images:
```bash
gcloud compute images list --filter="name:gpu-node*"
```

Delete specific image:
```bash
gcloud compute images delete IMAGE_NAME
```

Delete with project:
```bash
gcloud compute images delete IMAGE_NAME --project=PROJECT_ID
```

## Project Structure

```
.
├── aws/           # AWS-specific Packer templates
├── README.md      # This file
└── ...            # Additional configuration files
```

## Contributing

When adding new templates or modifying existing ones:
1. Always run `packer fmt` to maintain consistent formatting
2. Validate your changes with `packer validate`
3. Test builds in a development environment before committing

