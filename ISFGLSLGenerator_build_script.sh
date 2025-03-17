#!/bin/sh

export PATH="/opt/homebrew/bin:$PATH"

# this script needs to be run from xcode, which supplies the env vars used below.

echo "Processing ISFGLSLGenerator external build script..."

# this is the directory we're telling cmake to build
LOCAL_SRC_DIR="${PROJECT_DIR}/submodules/ISFGLSLGenerator"

# we're going to make this directory, and put all the cmake files for this project in it
LOCAL_BUILD_DIR="${PROJECT_TEMP_ROOT}/ISFGLSLGenerator.build"

LOCAL_INSTALL_DIR="${LOCAL_SRC_DIR}/build/install"

# make sure that cmake has created a build system in the build dir (if we don't, the 'clean' command may fail)
cmake -S "${LOCAL_SRC_DIR}" -B "${LOCAL_BUILD_DIR}"
#cmake -S "${LOCAL_SRC_DIR}" -B "${LOCAL_BUILD_DIR}" -G Xcode

# this is a "flag file"- its contents are irrelevant, the file's existence indicates state
LOCAL_BUILD_FILE_FLAG="${LOCAL_BUILD_DIR}/ISFGLSLGeneratorPreventCleanBuild"
# if the file at this path does NOT exist, this is either a first-time build or the user chose to do a clean build (which deleted the file).  in either case, force a clean build immediately!
if [ ! -f $LOCAL_BUILD_FILE_FLAG ] || [ "${ACTION}" = "clean" ]
then
	echo "performing a clean..."
	cmake --build "${LOCAL_BUILD_DIR}" --target clean
	echo "1">"${LOCAL_BUILD_FILE_FLAG}"
fi

# if this is a clean action, we're done- return before we build...
if [ "${ACTION}" = "clean" ]
then
	echo "bailing, clean complete..."
	exit 0
fi

echo "buliding ISFGLSLGenerator..."

cmake --build "${LOCAL_BUILD_DIR}" --config RelWithDebInfo
#cmake --build "${LOCAL_BUILD_DIR}" --config ${CONFIGURATION}

cmake --install "${LOCAL_BUILD_DIR}" --prefix "${LOCAL_INSTALL_DIR}"

codesign --timestamp --options runtime -f -s "Developer ID Application: Vidvox, LLC" "${LOCAL_INSTALL_DIR}/lib/liBISFGLSLGenerator.dylib"
