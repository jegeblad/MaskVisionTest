# MaskVisionTest

Command line example with Apple Vision foreground masking.

## Description

This is a small example / experiment with Apple Vision's framework Foreground Masking, which segments foreground objects from the background in an image.

It uses:
• VNGenerateForegroundInstanceMaskRequest to create a request to perform segmentation
• VNInstanceMaskObservation.instanceMask to get the instance mask, that for each pixel specifies which object instance the pixel belongs to
• VNInstanceMaskObservation.allInstances to output an image for each mask

This is a command line utility for macOS Sonoma (and above?), but the code should work fine with GUI iOS and macOS applications.

 