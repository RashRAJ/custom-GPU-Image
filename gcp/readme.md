# GCP

## Useful GCloud Commands

### Check GPU Availability in Your Zone
```bash
gcloud compute accelerator-types list --filter="zone:europe-west1-c"
```
Use this command to verify if specific GPU types are available in your target zone before configuring them in your Packer template.

### List Debian Images
```bash
gcloud compute images list --project debian-cloud --filter="family:debian-12"
```
Use this command to find the latest Debian 12 images for use as source images in your builds.
