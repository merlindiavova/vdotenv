# MDIA vDOTENV
A small library for reading and loading environment variables.

*__IMPORTANT: Make sure any environment files with sensitive information is added to your .gitignore. Never check-in these files__*

## Quick start

Create a `.env` file in your project root with the following contents

```sh
PULUMI_ACCESS_TOKEN=topsecret
PULUMI_BACKEND_URL=s3://your-pulumi-state-bucket
```

In your application import the library and call `vdotenv.load_env_default()` to
load the `.env` file.

```v
module main

import os
import mdia.vdotenv

fn main() {
	vdotenv.load_env_default() or { panic(err) }

	println(os.getenv('PULUMI_ACCESS_TOKEN'))
	println(os.getenv('PULUMI_BACKEND_URL'))
}
```

Running the above code will print the following in your terminal

```sh
topsecret
s3://your-pulumi-state-bucket
```

## Defining Environment Variables

This library tries to be as flexible as `sh` when handling environment variable declarations. Therefore, you can define your environment variables as you would in your shellscripts.

Below are some examples of supported environment variable declarations:

 - `export PULUMI_ACCESS_TOKEN=topsecret`
 - `readonly PULUMI_BACKEND_URL=s3://your-pulumi-state-bucket`
 - `readonly export METAL_AUTH_TOKEN='top-secret'`
 - `METAL_PROJECT_ID=af7eff2b-2a0f-4a8a-bd1d-4cc0a909d786`
 - `METAL_EXT_ASSET_PATH="${PULUMI_BACKEND_URL}/${METAL_PROJECT_ID}"`

### Important
Only variables in `"double quoted"` declaration values will be expanded. Variables found in single quoted or unquoted declaration values will be parsed as is.

Example

```sh
M3O_API_CMD='m3o --api-key="${M3O_API_TOKEN}" explore'
```
will return the literal
```sh
m3o --api-key="${M3O_API_TOKEN}" explore
```

## Loading Environment Variables

Environment files can be loaded using `vdotenv.load_env_default()` and `vdotenv.load_env`

`vdotenv.load_env_default()` uses default configurations to load your environment file which must be in the current directory and be name `.env`

`vdotenv.load_env` allows custom configurations on how your environment files are loaded.

```v
module main

import os
import mdia.vdotenv

fn main() {
	vdotenv.load_env(
		paths: ['.env', '.winry'],
		strict: false,
		required_keys: ['PULUMI_ACCESS_TOKEN', 'PULUMI_BACKEND_URL']
	) or { panic(err) }

	println(os.getenv('PULUMI_ACCESS_TOKEN'))
	println(os.getenv('PULUMI_BACKEND_URL'))
}
```

| Config Name     | Type     | Default     | Notes                             |
|-----------------|----------|-------------|-----------------------------------|
| paths           | []string | []          | Optional relative or absolute paths to environment files |
| override        | bool     | false       | Override existing environment variables |
| strict          | bool     | true        | Returns an error if a referenced  variable is not set |
| required_keys   | []string | []          | Optional set of required keys. An error will be returned if any required key is not set, whether in strict mode  or not. |

## Accessing Environment Variables

Once loaded you can access the environment variables using `os.getenv` and `os.getenv_opt`.

`vdotenv.load_env_default()` and `vdotenv.load_env` return a map of all the loaded environment variables. This can be handy as you do not have to keep calling `os.getenv*` to access your variables.

```v
module main

import os
import mdia.vdotenv

fn main() {
	env := vdotenv.load_env(
		paths: ['.env', '.winry'],
		strict: false,
		required_keys: ['PULUMI_ACCESS_TOKEN', 'PULUMI_BACKEND_URL']
	) or { panic(err) }

	println(env['PULUMI_ACCESS_TOKEN'])
	println(env['PULUMI_BACKEND_URL'])
}
```
>For best results I recommend using this with `strict: true` and passing `required_keys`

The library comes with 2 convenience functions `vdotenv.env` and `vdotenv.env_or_default`.

 - `vdotenv.env` - Returns an error if the requested variable it not set.
 - `vdotenv.env_or_default` - If the requested variable is not set use the given default.
