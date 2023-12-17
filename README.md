# Röntgen

Submitting a job

    ```
    aws batch submit-job --job-name test-2 --job-queue roentgen-job-queue --job-definition roentgen-job-definition
    ```

## Stretch Goals

1. Smarter instance type script

## Notes

* Exporting ssh key

    ```
    terraform output -raw private_key > ~/.ssh/tf-key.pem
    chmod 400 ~/.ssh/tf-key.pem
    ```
