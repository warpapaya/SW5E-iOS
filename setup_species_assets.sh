#!/bin/bash
cd /Users/citadel/clawd/projects/sw5e-ios

# Remove any failed attempts
rm -rf Resources/Assets.xcassets/Species_U*.imageset 2>/dev/null

for species in arion sylari vrask keth naxxid drifborn; do
    # Capitalize first letter using bash parameter expansion
    name="${species^}"
    dir="Resources/Assets.xcassets/Species_${name}.imageset"
    
    mkdir -p "$dir"
    cp ~/clawd/data/echoveil/species/${species}.png "$dir/${species}.png"
    
    cat > "$dir/Contents.json" << ENDJSON
{
  "images": [
    { "filename": "${species}.png", "idiom": "universal", "scale": "1x" },
    { "idiom": "universal", "scale": "2x" },
    { "idiom": "universal", "scale": "3x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
ENDJSON
    
    echo "Created: $dir"
done

echo "DONE - All assets created"
