#!/usr/bin/env bash

INPUT_FILE="temple.blend"
START_FRAME=1
END_FRAME=4
INPUT_DIR="/tmp/input"
SCRIPTS_DIR="/tmp/scripts"
OUTPUT_DIR="/tmp/output"
BLENDER_IMAGE="blendergrid/blender:4.4"
BUCKET="blendergrid-dev-us-east-1"

# Download
aws s3 sync "s3://$BUCKET/eevee/input/" "$INPUT_DIR/" 
aws s3 sync "s3://$BUCKET/eevee/scripts/" "$SCRIPTS_DIR/" 

# Render
mkdir -p "$OUTPUT_DIR"
for frame in {$START_FRAME..$END_FRAME}
do
    docker run --rm \
        --name eevee-render \
        --mount "type=bind,src=$INPUT_DIR,dst=/tmp/input,ro" \
        --mount "type=bind,src=$SCRIPTS_DIR,dst=/tmp/scripts,ro" \
        --mount "type=bind,src=$OUTPUT_DIR,dst=/tmp/output" \
        "$BLENDER_IMAGE" \
        "/tmp/input/$INPUT_FILE" \
        --python "/tmp/scripts/load_settings.py" \
        --render-output "/tmp/output/frame-####" \
        --render-frame "$frame" \
        -- \
        --settings-file "/tmp/input/settings.json"
done

# Upload
aws s3 sync "$OUTPUT_DIR/" "s3://$BUCKET/eevee/output/"

# TODO: Save the logs
# docker logs eevee-render ...

# Cleanup
rm -r "$INPUT_DIR"
rm -r "$SCRIPTS_DIR"
rm -r "$OUTPUT_DIR"

