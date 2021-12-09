echo "Processing deploy.sh"
# Set EB BUCKET as env variable
EB_BUCKET=elasticbeanstalk-us-west-2-797136058145
# Set ECR REPO as env variable
ECR_REPO=797136058145.dkr.ecr.us-west-2.amazonaws.com/mm
# Set the default region for aws cli
aws configure set default.region us-west-2
# securely log in to ECR
eval $(aws ecr get-login --no-include-email --region us-west-2)
# Build docker image based on our default Dockerfile
docker build -t wesget/mm .
# tag the image with the Travis-CI SHA
docker tag wesget/mm:latest 797136058145.dkr.ecr.us-west-2.amazonaws.com/mm:$TRAVIS_COMMIT
# Push built image to ECS
docker push 797136058145.dkr.ecr.us-west-2.amazonaws.com/mm:$TRAVIS_COMMIT
# Use the linux sed command to replace the text '<VERSION>' in our Dockerrun file with the Travis-CI SHA
sed -i='' "s/<VERSION>/$TRAVIS_COMMIT/" Dockerrun.aws.json
# Zip up our modified Dockerrun with our .ebextensions directory
zip -r mm-prod-deploy.zip Dockerrun.aws.json .ebextensions
# verify contents of the zip file
unzip -l mm-prod-deploy.zip
# Upload zip file to s3 bucket
aws s3 cp mm-prod-deploy.zip s3://$EB_BUCKET/mm-prod-deploy.zip
# Create a new application version with new Dockerrun
aws elasticbeanstalk create-application-version --application-name mm --version-label $TRAVIS_COMMIT --source-bundle S3Bucket=$EB_BUCKET,S3Key=mm-prod-deploy.zip
# Update environment to use new version number
aws elasticbeanstalk update-environment --environment-name Mm-env-1 --version-label $TRAVIS_COMMIT