module main

import mdia.vdotenv
import os

fn testsuite_begin() {
	base_dir := @VMODROOT
	os.cp_all('${base_dir}/fixtures/', base_dir, true) or { panic(err) }
}

fn testsuite_end() {
	base_dir := @VMODROOT
	os.rm('${base_dir}/.env') or { panic(err) }
	os.rm('${base_dir}/.env.example') or { panic(err) }
	os.rm('${base_dir}/.env.extended') or { panic(err) }
}

fn test_load_env_default() {
	vdotenv.load_env_default() or { panic(err) }
	home := os.getenv('HOME')
	user := os.getenv('USER')

	assert os.getenv('RAYNS_OPERATOR') == 'ves'
	assert os.getenv('RAYNS_SERVER') == '10.5.3.10'
	assert os.getenv('RAYNS_ID') == '$home/ves/.ssh/id_${user}_rsa'
	assert os.getenv('RAYNS_REMOTE') == '/midna'
	assert os.getenv('RAYNS_PORT') == '1023'
	assert os.getenv('NOT_EXPANDABLE') == '\${HOME}/\${USER_ID}'
}

fn test_map() {
	env := vdotenv.load_env_default() or { panic(err) }
	home := os.getenv('HOME')
	user := os.getenv('USER')

	assert env['RAYNS_OPERATOR'] == 'ves'
	assert env['RAYNS_SERVER'] == '10.5.3.10'
	assert env['RAYNS_ID'] == '$home/ves/.ssh/id_${user}_rsa'
	assert env['RAYNS_REMOTE'] == '/midna'
	assert env['RAYNS_PORT'] == '1023'
	assert env['NOT_EXPANDABLE'] == '\${HOME}/\${USER_ID}'
}

fn test_load_env_required_keys() {
	vdotenv.load_env(required_keys: ['VDOTENV_ENVR']) or {
		if err.msg().contains('VDOTENV_ENVR') {
			assert true
		} else {
			panic(err)
		}
	}
}

fn test_load_env_with_multiple_path() {
	vdotenv.load_env(
		paths: ['.env', '.env.example']
	) or { panic(err) }

	user := os.getenv('USER')

	// from .env
	assert os.getenv('RAYNS_OPERATOR') == 'ves'

	// from .env.example
	assert os.getenv('VDOTENV_PATH') == 'path_here'
	assert os.getenv('VDOTENV_PATH_MERGED') == 'path_here/expands/$user'
	assert os.getenv('VDOTENV_OS') == "10.5.20.4 'Operator': ves"
	assert os.getenv('VDOTENV_ENVIRONMENT') == 'development'
	assert os.getenv('VDOTENV_ENVI') == ''
}

fn test_required_keys_cannot_be_used_with_multiple_path() {
	vdotenv.load_env(
		paths: ['.env', '.env.example']
		required_keys: ['VDOTENV_ENVR']
	) or {
		if err.msg() == 'Required keys cannot be set with multple file paths' {
			assert true
		} else {
			panic(err)
		}
	}
}

fn test_load_env_app_vars() {
	vdotenv.load_env(
		paths: ['.env.extended']
		strict: false
	) or { panic(err) }

	assert os.getenv('DATABASE_PORT_MAP') == '1309'
	assert os.getenv('APP_PORT_MAP') == '1086'
	assert os.getenv('APP_TLS_PORT_MAP') == '1085'
	assert os.getenv('APP_DOMAIN') == 'example.xlocal'
	assert os.getenv('REMOTE_DOMAIN') == ''
	assert os.getenv('REMOTE_URL') == 'https://www.'
	assert os.getenv('REDIS_PORT_MAP') == '1384'
	assert os.getenv('REDIS_COMMANDER_PORT_MAP') == '1385'
	assert os.getenv('REDIS_COMMANDER_URL') == 'http://${os.getenv('APP_DOMAIN')}:${os.getenv('REDIS_COMMANDER_PORT_MAP')}'
	assert os.getenv('DEV_MODE') == 'true'
	assert os.getenv('APP_NAME') == 'examplexloc'
	assert os.getenv('APP_ENV') == 'dev'
	assert os.getenv('APP_DEBUG') == 'true'
	assert os.getenv('APP_URL') == 'https://www.${os.getenv('APP_DOMAIN')}'
	assert os.getenv('APP_HTTP_URL') == 'http://www.${os.getenv('APP_DOMAIN')}'
	assert os.getenv('DB_DRIVER') == 'mysql'
	assert os.getenv('DB_HOST') == 'database'
	assert os.getenv('DB_NAME') == 'examplexloc'
	assert os.getenv('DB_USERNAME') == 'examplexloc'
	assert os.getenv('DB_PASSWORD') == 'secret'
	assert os.getenv('DB_TABLE_PREFIX') == ''
	assert os.getenv('DATABASE_DSN') == 'mysql:host=${os.getenv('DB_HOST')};dbname=${os.getenv('DB_NAME')}'
	assert os.getenv('DATABASE_URL') == 'mysql://${os.getenv('DB_USERNAME')}:${os.getenv('DB_PASSWORD')}@${os.getenv('DB_HOST')}:3306/${os.getenv('DB_NAME')}'
	assert os.getenv('REDIS_HOST') == 'examplexloc_redis'
	assert os.getenv('REDIS_PASSWORD') == ''
	assert os.getenv('REDIS_PORT') == '1379'
	assert os.getenv('REDIS_HOST_PATH') == '${os.getenv('REDIS_HOST')}:${os.getenv('REDIS_PORT')}'
	assert os.getenv('REDIS_DSN') == 'tcp://${os.getenv('REDIS_HOST_PATH')}'
	assert os.getenv('REDIS_PREFIX') == ''
	assert os.getenv('U_CLOUD_SLUG') == 'EXAMPLE.LOCAL'
	assert os.getenv('U_CLOUD_API_KEY') == 'a1eb8e2b-fe09-40eb-8c4b-9f2f1710ea01'
	assert os.getenv('U_CLOUD_API_SECRET') == '19d3a0df-17af-4aab-96d3-0c85d28d669c'
	assert os.getenv('U_CLOUD_URL') == 'example://${os.getenv('U_CLOUD_API_KEY')}:${os.getenv('U_CLOUD_API_SECRET')}@${os.getenv('U_CLOUD_SLUG')}'
	assert os.getenv('ENVIRONMENT') == '${os.getenv('APP_ENV')}'
	assert os.getenv('CRF_ENVIRONMENT') == '${os.getenv('APP_ENV')}'
	assert os.getenv('CRF_ENFORCE_DEPRECATION') == 'true'
	assert os.getenv('APP_ID') == 'EXAMPLExLOC--52918578-d994-4634-8301-14c747806950'
	assert os.getenv('SECURITY_KEY') == 'uproar rubber company unburned scurvy vanquish manlike fanfare appetite voter alarm reaffirm enjoyer cringe oxymoron sprang'
	assert os.getenv('DB_DRIVER') == 'mysql'
	assert os.getenv('DB_SERVER') == 'database'
	assert os.getenv('DB_PORT') == '3306'
	assert os.getenv('DB_DATABASE') == 'examplexloc'
	assert os.getenv('DB_USER') == 'examplexloc'
	assert os.getenv('DB_SCHEMA') == ''
	assert os.getenv('CODE_STYLE_PIPELINE') == 'phpcs:app phpcs:cli'
}
