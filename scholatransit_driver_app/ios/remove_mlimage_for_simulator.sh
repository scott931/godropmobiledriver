#!/bin/bash
# Remove MLImage framework for simulator builds
if [[ "$PLATFORM_NAME" == "iphonesimulator" ]]; then
    echo "Removing MLImage framework for simulator build..."
    FRAMEWORK_PATH="${PODS_ROOT}/MLImage/Frameworks/MLImage.framework"
    if [ -d "$FRAMEWORK_PATH" ]; then
        # Create a dummy framework to prevent linker errors
        mkdir -p "${BUILT_PRODUCTS_DIR}/MLImage.framework"
        echo "Created dummy MLImage framework for simulator"
    fi
fi
