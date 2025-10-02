#!/bin/bash
#
# Setup Standalone UIPlayground Project
# This copies your UI components to a clean project with ZERO packages
#

set -e  # Exit on error

echo "🎨 Setting up MeetMemento-UIOnly standalone project..."
echo ""

# Check if we're in the right directory
if [ ! -d "MeetMemento/Components" ]; then
    echo "❌ Error: Run this from the MeetMemento project root"
    exit 1
fi

# Target directory
TARGET_DIR="$HOME/Swift-projects/MeetMemento-UIOnly"

echo "📋 Step 1: Checking for existing project..."
if [ -d "$TARGET_DIR" ]; then
    echo "⚠️  Project already exists at: $TARGET_DIR"
    read -p "Do you want to overwrite the Components/Resources/Extensions? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
else
    echo "ℹ️  Project directory will be: $TARGET_DIR"
    echo "   You'll need to create the Xcode project there first."
    echo ""
    read -p "Have you created the Xcode project? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "📝 Please create the project first:"
        echo "   1. Open Xcode"
        echo "   2. File → New → Project"
        echo "   3. iOS → App"
        echo "   4. Product Name: MeetMemento-UIOnly"
        echo "   5. Save to: ~/Swift-projects/MeetMemento-UIOnly"
        echo ""
        echo "Then run this script again!"
        exit 0
    fi
fi

echo ""
echo "📦 Step 2: Copying UI components..."

# Create directories if they don't exist
mkdir -p "$TARGET_DIR/Components"
mkdir -p "$TARGET_DIR/Resources"
mkdir -p "$TARGET_DIR/Extensions"
mkdir -p "$TARGET_DIR/Showcases"

# Copy Components
echo "  → Components..."
cp -r MeetMemento/Components/* "$TARGET_DIR/Components/" 2>/dev/null || true

# Copy Resources (excluding Supabase config)
echo "  → Resources..."
cp MeetMemento/Resources/Theme.swift "$TARGET_DIR/Resources/" 2>/dev/null || true
cp MeetMemento/Resources/Theme+Optimized.swift "$TARGET_DIR/Resources/" 2>/dev/null || true
cp MeetMemento/Resources/Typography.swift "$TARGET_DIR/Resources/" 2>/dev/null || true
cp MeetMemento/Resources/Constants.swift "$TARGET_DIR/Resources/" 2>/dev/null || true
cp MeetMemento/Resources/Strings.swift "$TARGET_DIR/Resources/" 2>/dev/null || true

# Copy Extensions
echo "  → Extensions..."
cp MeetMemento/Extensions/Color+Theme.swift "$TARGET_DIR/Extensions/" 2>/dev/null || true
cp MeetMemento/Extensions/Date+Format.swift "$TARGET_DIR/Extensions/" 2>/dev/null || true

# Copy UIPlayground files
echo "  → UIPlayground files..."
cp UIPlayground/ComponentGallery.swift "$TARGET_DIR/" 2>/dev/null || true
cp UIPlayground/FastPreviewHelpers.swift "$TARGET_DIR/" 2>/dev/null || true
cp -r UIPlayground/Showcases/* "$TARGET_DIR/Showcases/" 2>/dev/null || true

echo ""
echo "✅ Files copied successfully!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Open the standalone project:"
echo "   cd ~/Swift-projects/MeetMemento-UIOnly"
echo "   open MeetMemento-UIOnly.xcodeproj"
echo ""
echo "2. Add files to project:"
echo "   - Right-click project in Navigator"
echo "   - 'Add Files to MeetMemento-UIOnly'"
echo "   - Select: Components, Resources, Extensions, Showcases folders"
echo "   - Also add: ComponentGallery.swift, FastPreviewHelpers.swift"
echo "   - Check '✅ Add to targets: MeetMemento-UIOnly'"
echo ""
echo "3. Update main app file to use ComponentGallery:"
echo "   @main"
echo "   struct MeetMemento_UIOnlyApp: App {"
echo "       var body: some Scene {"
echo "           WindowGroup { ComponentGallery() }"
echo "       }"
echo "   }"
echo ""
echo "4. Build and run (⌘R) - Should complete in 3-5 seconds! ⚡️"
echo ""
echo "🎨 Happy UI development!"

