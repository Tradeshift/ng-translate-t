#!/bin/bash -eu

BUILD_DIR=$(pwd)
BUILD_IMAGE=$(echo $JOB_BASE_NAME | tr '[:upper:]' '[:lower:]'):build-${BUILD_ID}
APP_DIR="/usr/src/app/"
# Get npm version from package.json or default
NPM_VERSION=${NPM_VERSION:-$(jq ".engines.npm // 6" package.json)}

# release env:
NPM_UPLOAD_TOKEN=${NPM_UPLOAD_TOKEN:-''}

# PR branch is more correct than PR-xxx
GIT_BRANCH=${CHANGE_BRANCH:-$GIT_BRANCH}
GIT_BRANCH=${GIT_BRANCH#origin/};

DOCKER_ARGS=(
	-u $(id -u)
	-e CI=true
	-e JENKINS_URL
	-e GIT_BRANCH
	-v $(pwd)/.npm:/.npm
	-v $(pwd)/.npmrc:/.npmrc
	-v $(pwd)/.npmrc:${APP_DIR}/.npmrc
	-v $(pwd)/.git:${APP_DIR}/.git
	-v $(pwd)/.eslintcache:${APP_DIR}/.eslintcache
	-v $(pwd)/package.json:${APP_DIR}/package.json
	-v $(pwd)/package-lock.json:${APP_DIR}/package-lock.json
	-v $(pwd)/build:$APP_DIR/build
	-v $(pwd)/coverage:$APP_DIR/coverage
	-v $(pwd)/dist:$APP_DIR/dist
	-v $(pwd)/logs:$APP_DIR/logs
	-v $(pwd)/resources:$APP_DIR/resources
)
DOCKER_UPLOAD_ARGS=(
	-e "NPM_TOKEN=${NPM_UPLOAD_TOKEN}"
	-e "GH_TOKEN=${GITHUB_CREDS_PSW}"
)

# package-lock is optional, make sure it exists:
[ -f package-lock.json ] || echo "{}" > package-lock.json
[ -f .eslintcache ] || echo "{}" > .eslintcache
# Public packages dont need specific npmrc:
echo "" > .npmrc;

mkdir -p build coverage dist logs .npm resources
chmod 777 build coverage dist logs .npm resources

docker build \
	--build-arg NODE_VERSION=$(cat .nvmrc) \
	--build-arg NPM_VERSION \
	--build-arg NPM_TOKEN \
	--build-arg APP_DIR \
	-t $BUILD_IMAGE .

docker run --rm \
	${DOCKER_ARGS[*]} \
	$BUILD_IMAGE \
	bash -c "npm run validate"

echo "[release] [Semantic release]: Analysis of 2 commits complete: no release"
echo "[release] [Semantic release]: HACKER TIME!"
echo "[release] [Semantic release]: NPM_VERSION == ${NPM_VERSION}"
echo "[release] [Semantic release]: BUILD_DIR == ${BUILD_DIR}"
echo "[release] [Semantic release]: BUILD_IMAGE == ${BUILD_IMAGE}"
echo "[release] [Semantic release]: APP_DIR == ${APP_DIR}"

docker run --rm \
	${DOCKER_ARGS[*]} \
	${DOCKER_UPLOAD_ARGS[*]} \
	$BUILD_IMAGE \
	bash -c 'npm run after-success'

# Hack for absolute paths in lcov files:
if [ -f  coverage/lcov.info ]; then
	sed -i "s|SF:${APP_DIR}|SF:${BUILD_DIR}/|g" coverage/lcov.info
fi


