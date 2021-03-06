#!/bin/bash

set -e
source $(dirname $0)/00-init-env.sh

#-------------------------------------------------------------------------------
# Install JHipster Dependencies and Server-side library
#-------------------------------------------------------------------------------
cd "$HOME"
if [[ "$JHI_REPO" == *"/jhipster" ]]; then
    echo "*** jhipster: use local version at JHI_REPO=$JHI_REPO"

    cd "$JHI_HOME"
    git --no-pager log -n 10 --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    ./mvnw clean install -Dgpg.skip=true

elif [[ "$JHI_LIB_BRANCH" == "release" ]]; then
    echo "*** jhipster: use release version"

else
    echo "*** jhipster: JHI_LIB_REPO=$JHI_LIB_REPO with JHI_LIB_BRANCH=$JHI_LIB_BRANCH"
    git clone "$JHI_LIB_REPO" jhipster
    cd jhipster
    if [ "$JHI_LIB_BRANCH" == "latest" ]; then
        LATEST=$(git describe --abbrev=0)
        git checkout "$LATEST"
    elif [ "$JHI_LIB_BRANCH" != "master" ]; then
        git checkout "$JHI_LIB_BRANCH"
    fi
    git --no-pager log -n 10 --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    test-integration/scripts/10-replace-version-jhipster.sh

    ./mvnw clean install -Dgpg.skip=true
    ls -al ~/.m2/repository/io/github/jhipster/jhipster-framework/
    ls -al ~/.m2/repository/io/github/jhipster/jhipster-dependencies/
    ls -al ~/.m2/repository/io/github/jhipster/jhipster-parent/
fi

#-------------------------------------------------------------------------------
# Install JHipster Generator
#-------------------------------------------------------------------------------
cd "$HOME"
if [[ "$JHI_REPO" == *"/generator-jhipster" ]]; then
    echo "*** generator-jhipster: use local version at JHI_REPO=$JHI_REPO"

    cd "$JHI_HOME"
    git --no-pager log -n 10 --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    npm ci
    npm link
    if [[ "$JHI_APP" == "" || "$JHI_APP" == "ngx-default" ]]; then
        npm test
    fi

elif [[ "$JHI_GEN_BRANCH" == "release" ]]; then
    echo "*** generator-jhipster: use release version"
    npm install -g generator-jhipster

else
    echo "*** generator-jhipster: JHI_GEN_REPO=$JHI_GEN_REPO with JHI_GEN_BRANCH=$JHI_GEN_BRANCH"
    git clone "$JHI_GEN_REPO" generator-jhipster
    cd generator-jhipster
    if [ "$JHI_GEN_BRANCH" == "latest" ]; then
        LATEST=$(git describe --abbrev=0)
        git checkout "$LATEST"
    elif [ "$JHI_GEN_BRANCH" != "master" ]; then
        git checkout "$JHI_GEN_BRANCH"
    fi
    git --no-pager log -n 10 --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    npm ci
    npm link
fi

#-------------------------------------------------------------------------------
# Override config
#-------------------------------------------------------------------------------

# replace 00-init-env.sh
cp "$JHI_CLONED"/test-integration/scripts/00-init-env.sh "$JHI_HOME"/test-integration/scripts/

# copy all samples
cp -R "$JHI_CLONED"/test-integration/samples-vuejs/* "$JHI_HOME"/test-integration/samples/

#-------------------------------------------------------------------------------
# Install yeoman
#-------------------------------------------------------------------------------
npm install -g yo

#-------------------------------------------------------------------------------
# Install JHipster Vue.js
#-------------------------------------------------------------------------------
cd "$JHI_CLONED"/
npm ci
npm link
npm link generator-jhipster
ls -al /home/travis/.nvm/versions/node/v10.15.3/lib/node_modules/

npm run lint
if [[ "$JHI_APP" == "" || "$JHI_APP" == "vuejs-default" ]]; then
    # Run generator tests only for some configurations
    npm test
fi
