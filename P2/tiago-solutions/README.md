## Tiago's solutions

> I used NodeJS v14.15.4

### Setup

Copy the `addresses` file you got in your e-mail to the root of this folder. Should look like `addresses.test`.

Create an `.env` (copy from `.env.example`) file with the variables you got in your e-mail.
The `PROVIDER_URL` is the address of the Bob node you are running. You can find this out by running `docker ps` and chekcking the container's port mapping. Should be something like `http://localhost:55008`.

Run `npm install` to install dependencies.

```bash
cp .env.example .env

npm install
```

### How to run

```bash
node index.js # runs all of the solutions

# OR

node index.js <badparity|daodown|faildice|notawallet> # runs a particular solution
```