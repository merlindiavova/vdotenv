module vdotenv

import os

const (
	exit_not_found   = 253
	exit_read_failed = 21
)

pub struct LoadEnvConfig {
	paths         []string
	override      bool
	strict        bool = true
	required_keys []string
}

fn is_nested(value string) bool {
	return value.contains('\${') && value.contains('\${')
}

fn is_expandable(value string) bool {
	return !value.starts_with("'")
}

// load_env_default uses default configurations to load your environment file which must be in the current directory and be name `.env`
pub fn load_env_default() ?map[string]string {
	return load_env(override: false) or { return err }
}

// load_env allows custom configurations on how your environment files are loaded.
pub fn load_env(c LoadEnvConfig) ?map[string]string {
	mut env_vars := map[string]string{}

	if c.paths.len == 1 {
		return load_env_file(c.paths[0], c.override, c.strict, ...c.required_keys) or { return err }
	} else if c.paths.len > 1 {
		if c.required_keys.len > 0 {
			return error('Required keys cannot be set with multple file paths')
		}
		for i := 0; i < c.paths.len; i++ {
			path := c.paths[i]
			vars := load_env_file(path, c.override, c.strict, ...c.required_keys) or { return err }

			for key, value in vars {
				env_vars[key] = value
			}
		}

		return env_vars
	}

	return load_env_file('.env', c.override, c.strict, ...c.required_keys) or { return err }
}

// env returns an error if the requested variable it not set
pub fn env(key string) ?string {
	return os.getenv_opt(key) or {
		return error_with_code('Cannot find env var $key', exit_not_found)
	}
}

// env_or_default returns the given default variable if the requested variable is not set
pub fn env_or_default(key string, default string) string {
	return os.getenv_opt(key) or { return default }
}

fn parse_key_hint(hint string) string {
	if hint.len > 15 && hint[0..16] == 'readonly export ' {
		return hint[16..]
	}

	if hint.len > 6 && hint[0..7] == 'export ' {
		return hint[7..]
	}

	if hint.len > 8 && hint[0..9] == 'readonly ' {
		return hint[9..]
	}

	return hint
}

fn load_env_file(path string, override bool, strict bool, required_keys ...string) ?map[string]string {
	if path == '' {
		return error_with_code('Cannot resolve path', exit_not_found)
	}

	if !os.exists(path) {
		return error_with_code('env file not found.', exit_not_found)
	}

	contents := os.read_file(path) or {
		return error_with_code('env file is not readable', exit_read_failed)
	}

	lines := contents.split_into_lines()
	mut loaded_keys := []string{}
	mut env_vars := map[string]string{}

	for i := 0; i < lines.len; i++ {
		line := lines[i]

		if line.starts_with('#') || line == '' {
			continue
		}

		env_var_split := line.trim_space().split_nth('=', 2)

		if env_var_split.len != 2 {
			continue
		}

		key_hint := env_var_split[0].trim_space()

		key := parse_key_hint(key_hint)

		raw_value := env_var_split[1].trim_space()
		value_hint := raw_value.trim('"\'')

		if value_hint == '' || !is_expandable(raw_value) || !is_nested(value_hint) {
			env_vars[key] = value_hint
			os.setenv(key, value_hint, override)
			loaded_keys << key
			continue
		}

		mut value := value_hint

		split := value_hint.split('\${')

		for hint in split {
			if hint == '' {
				continue
			}

			position := hint.index('}') or { 0 }
			env_name_hint := hint.substr(0, position)
			env_value := os.getenv_opt(env_name_hint) or {
				if strict {
					return error('Env var [$env_name_hint] not set.')
				}

				'\${$env_name_hint}'
			}

			value = value.replace('\${$env_name_hint}', env_value)
		}

		env_vars[key] = value
		os.setenv(key, value, override)
		loaded_keys << key
	}

	if required_keys.len > 0 {
		check_missing_keys(loaded_keys, required_keys) or { return err }
	}

	return env_vars
}

fn check_missing_keys(loaded_keys []string, required_keys []string) ? {
	mut missing_keys := []string{}

	for key in required_keys {
		if key !in loaded_keys {
			missing_keys << key
		}
	}

	if missing_keys.len > 0 {
		mut multi := 'variables'

		if missing_keys.len == 1 {
			multi = 'variable'
		}

		return error_with_code('Failed to get required environment $multi: ${missing_keys.join(', ')}',
			exit_not_found)
	}
}
