## Team Members:
- Grant Biellak
- Madhuri Waghmode
- Radhika Mandhanya
- Simon Truong

For sprints 5 and 6, the workflow moved off of UNIX and was performed on Python via PySpark. Although sprint 5's notebook is capable of being fully runnable locally, sprint 6 is intended to be compatible with running on Google's GCP Dataproc and the lines shown are to only give example of the lines we used.



The files can be found here in the same folder or at the Google Drive Link:
https://drive.google.com/drive/folders/1qi4VpOdaePq04Gh0-5vhbWjlWt8GS79L?usp=drive_link


# Sprint/Project Assignment 6:
## Setup Environment Variables:
```
BUCKET=wtbm-spotify
CODE_URI=gs://$BUCKET/code/projectassignment6.py
REGION=us-west1
```
## Run PySpark Script on gcloud:
```
gcloud dataproc batches submit pyspark "$CODE_URI"   --region="$REGION"   --deps-bucket="gs://$BUCKET"   --properties="\
spark.dynamicAllocation.enabled=false,\
spark.driver.cores=4,\
spark.driver.memory=8g,\
spark.executor.instances=7,\
spark.executor.cores=4,\
spark.executor.memory=4g"
```
## Input/Output Locations in Bucket:
Input Dataset: `gs://wtbm-spotify/data/SpotifyFeatures.csv`

Output Folder: `gs://wtbm-spotify/out/`

