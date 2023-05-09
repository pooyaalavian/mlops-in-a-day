import os
import argparse
import pandas as pd
import numpy as np
import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.metrics import r2_score
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
from parser import parse_args


def data_prep(data, test_train_ratio):
    print("input data:", data)
    
    df = pd.read_csv(data, index_col=0)
    df['hr_sin'] =  df['hr'].apply(lambda x: np.sin(2 * np.pi * x / 24))
    df['hr_cos'] =  df['hr'].apply(lambda x: np.cos(2 * np.pi * x / 24))
    df['temp2'] = (df['temp'] - 0.6)**2
    X = df[['hr', 'hr_sin', 'hr_cos', 'temp', 'temp2', 'hum', 'windspeed','workingday', 'weathersit' ]]
    y = df['cnt']
    mlflow.log_metric("num_samples", X.shape[0])
    mlflow.log_metric("num_features", X.shape[1] )

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=test_train_ratio,)
    return X_train, X_test, y_train, y_test


def train_model(X_train, X_test, y_train, y_test, n_estimators, learning_rate):

    # convert the dataframe values to array
    X_train = X_train.values
    X_test = X_test.values

    print(f"Training with data of shape {X_train.shape}")

    # clf = GradientBoostingRegressor( n_estimators=n_estimators, learning_rate=learning_rate)
    clf = RandomForestRegressor( n_estimators=n_estimators, )
    clf.fit(X_train, y_train)
    y_pred = clf.predict(X_test)
    
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    mlflow.log_metric('rmse',rmse)
    
    mlflow.log_metric('r2_score',r2_score(y_test, y_pred))
    return clf


def main():
    """Main function of the script."""

    args = parse_args()
    print(" ".join(f"{k}={v}" for k, v in vars(args).items()))

    # Start Logging
    mlflow.start_run()

    # enable autologging
    mlflow.sklearn.autolog()

    X_train, X_test, y_train, y_test = data_prep(args.data, args.test_train_ratio)

    model = train_model(X_train, X_test, y_train, y_test, args.n_estimators, args.learning_rate)

    # Registering the model to the workspace
    print("Registering the model via MLFlow")
    mlflow.sklearn.log_model(
        sk_model=model,
        registered_model_name=args.registered_model_name,
        artifact_path=args.registered_model_name,
    )

    # Saving the model to a file
    mlflow.sklearn.save_model(
        sk_model=model,
        path=os.path.join(args.registered_model_name, "trained_model"),
    )
    
    # Stop Logging
    mlflow.end_run()

if __name__ == "__main__":
    main()
