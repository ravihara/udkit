# udkit

User development kit with helper utilities.

## Motto

The purpose of this project is to unclutter .bashrc a bit or, better yet, propose a version of it which I found simple and manageable. You are encouraged to use it at your own discretion.

It would be great if you find this helpful!

## How to use

Follow the steps to setup the bash customizations by utilizing the `udkit`.

- git clone git@github.com:ravihara/udkit.git ~/.udkit
- Edit your ~/.bashrc file and add the following lines.

  ```bash
  ## udkit configuration - Should be towards the end
  if [ -d "$HOME/.udkit" ]; then
      source "$HOME/.udkit/udkitrc"
  fi
  ```

- Close the terminal and open a new one to access the scripts and custom configurations as configured in `udkit`.

## Things to note

The `udkit` internally configures [direnv](https://direnv.net/) utility. Hence, you can make use of `.envrc` file to simplify your per-folder environment configuration. You can also have a default .envrc file in your _HOME_ folder with default environment (Ex., default version of _OpenJDK_, _Golang_, _Node.js_ and so on).
