# mautic-segment-update

## Functionality

    The script loops though the email addresses in the text file, creates contacts for them in Mautic if they don't exist, creates the Segment if it does not exist and adds all the contacts to the segment.

## Usage

- Clone the repo
- Add your emails to the emails.txt file - one email address per line.
- Export your ENV variables:

    To generate a basic token base64 encode `your_mautic_email:your_mautic_password`
    ```
    export MAUTIC_AUTH="token"
    ``` 

    Base URL example `https://mymauticinstance.tld`
    ```
    export MAUTIC_BASE_URL="base_url" 
    ```

- Install jq

    https://stedolan.github.io/jq/download/

- Make the script executable:
    ```
    chmod +x update-segment.sh
    ```

- Run the script:
    ```
    ./update-segment.sh my-fancy-segment-name
    ```