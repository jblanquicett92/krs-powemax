#!/bin/bash
export FLUTTER_GEMMA_LIB_DIR="/mnt/c/repos/krs-powemax/build/linux/x64/debug/bundle/lib"
export VK_ICD_FILENAMES=""
export WGPU_BACKEND="empty"
dart run test/test_interactive_chat.dart
