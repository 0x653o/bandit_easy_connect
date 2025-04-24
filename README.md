# bandit_for_easy_connect

## Usage:

### 1. Make the script executable
```sh
chmod +x bandit.sh
```
### 2. Run the script:
```sh
./bandit.sh <bandit_number> <password>

Example: ./bandit.sh 0 bandit

<bandit_number>: Bandit level number (e.g., 0, 1, 2, ...)
```
```
<password>: Password for the corresponding bandit level
```
>Note: The password is passed as a command-line argument and may be stored in shell history.

and it will make an file of passwd
if you typed worng passwd?

it will update your passwd after you connected sucsessfully
