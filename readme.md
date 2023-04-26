# MLOps In A Day Workshop

## Introduction

This repo tries to build a realistic MLOps pipeline including infrastructure-as-Code, ML model training,
ML model deployment, model monitoring, retrain-on-push, retrain-on-drift, ... .

## Getting Started

To get started, clone this repo locally. 

### Prerequisites
Make sure the following are installed:
- Azure CLI (`az`)
- Python 3.10
- VS Code (for Azure Function deployment)
- Permission to deploy resources in your tenant/subscription
- Permission to create a service principal or access to an existing service principal


### 1. Infrastructure deployment

Run the `deploy.ps1` powershell script to deploy the resources and create SQL table schemas.

If you'd like to do this manually instead, read [this](./infrastructure/deploy.md).

### 2. Deploy Azure Function

There are two Azure functions in [`azfunctions`](./azfunctions) folder. 
- `DataLogger` function receives data from a) prediction endpoint of our deployed model or b) real outcome of events (simulated) and logs data into the SQL database.
- `ModelMonitor` is a time triggered function that runs every `x` minutes and evaluates the performance of the model. If the performance is below a certain threshold, it triggers a retraining pipeline.

We use VS Code Azure Function extension for deployment.

### 3. Deploy the data science piece

