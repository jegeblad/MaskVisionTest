# MaskVisionTest

Command line example with Apple Vision foreground masking.

## Description

I couldn't find any simple implementation example in Objective-C of Apple's Vision framework for foreground masking, so I made this small example and personal test.  

This is a small example / experiment with Apple Vision's framework Foreground Masking, which segments foreground objects from the background in an image.

It uses:

* VNGenerateForegroundInstanceMaskRequest to create a request to perform segmentation
* VNInstanceMaskObservation.instanceMask to get the instance mask, that for each pixel specifies which object instance the pixel belongs to
* VNInstanceMaskObservation.allInstances to output an image for each mask

This is a command line utility for macOS Sonoma (and above?), but the code should work fine with GUI iOS and macOS applications.

## Example Data

Running this tool with: 

    MaskingTest test_image/test_image.jpg test/
    
Will output the images in the test_output folder.

This performs the segmentation on the following image

![image](test_image/test_image.jpg)

And should output the masks of the objects found as well as the following separate images:

First the background (index 0):
![image](test_output/masked_image_0.png)

Object 1:
![image](test_output/masked_image_1.png)

Object 2:
![image](test_output/masked_image_2.png)

Object 3:
![image](test_output/masked_image_3.png)

The first output masked image is the background.