#import <Vision/Vision.h>
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>


// Helper -- Create a CGImage from a CVPixelBufferRef
CGImageRef cgImageFromCV(CVPixelBufferRef pixelBufferRef)
{
	CIContext * context = [[CIContext alloc] init];
	CIImage * ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBufferRef];
	return [context createCGImage:ciImage fromRect:ciImage.extent];
}


// Helper -- Save a pixel buffer to PNG file
void saveCVPixelBufferRef(CVPixelBufferRef pixelBuffer, NSString * targetFilename)
{
	CGImageRef cgImage = cgImageFromCV(pixelBuffer);
	NSBitmapImageRep * resultImage = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSData *bitmapData = [resultImage representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
	if (![bitmapData writeToFile:targetFilename atomically:YES])
	{
		printf("Error writing image: %s\n", [targetFilename UTF8String]);
		exit(-1);
	}
}



void outputMaskObservation(VNImageRequestHandler * imageRequestHandler, VNInstanceMaskObservation * maskObservation, NSInteger idx, NSString * outputFolder)
{
	NSIndexSet * iSet = [NSIndexSet indexSetWithIndex:idx];

	NSError * error = nil;
	CVPixelBufferRef  maskedImage = [maskObservation generateMaskedImageOfInstances:iSet
																 fromRequestHandler:imageRequestHandler
														   croppedToInstancesExtent:NO
																			  error:&error];
	if (error)
	{
		printf("Error: %s\n", [[error description] UTF8String]);
		exit(-1);
	}
	
	NSString * maskedImageFilename = [NSString stringWithFormat:@"%@/masked_image_%ld.png", outputFolder, idx];
	printf("Saving masked image to: %s\n", [maskedImageFilename UTF8String]);
	saveCVPixelBufferRef(maskedImage, maskedImageFilename);
	
	
	CVPixelBufferRef  mask = [maskObservation generateScaledMaskForImageForInstances:iSet
																		 fromRequestHandler:imageRequestHandler
																					  error:&error];
	
	if (error)
	{
		printf("Error: %s\n", [[error description] UTF8String]);
		exit(-1);
	}
	NSString * maskFilename = [NSString stringWithFormat:@"%@/mask_%ld.png", outputFolder, idx];
	printf("Saving mask to: %s\n", [maskFilename UTF8String]);
	saveCVPixelBufferRef(mask, maskFilename);
}


void performMaskingOfImage(NSString * filename, NSString * outputFolder)
{
	NSImage * img = [[NSImage alloc] initWithContentsOfFile:filename];
	NSBitmapImageRep * bitmap = (NSBitmapImageRep * )[img.representations objectAtIndex:0];
	CGImageRef cgImage = bitmap.CGImage;
	VNImageRequestHandler * imageRequestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
	NSError * error = nil;
	
	// Create the vision requestion
	VNGenerateForegroundInstanceMaskRequest * maskRequest = [[VNGenerateForegroundInstanceMaskRequest alloc] initWithCompletionHandler:^(VNRequest * request, NSError * err)
	{
		if (err)
		{
			printf("Error performing request: %s\n", [[err description] UTF8String]);
			exit(-1);
		}
		
		if ([request isKindOfClass:[VNGenerateForegroundInstanceMaskRequest class]])
		{
			VNGenerateForegroundInstanceMaskRequest * maskRequest = (VNGenerateForegroundInstanceMaskRequest*)request;
			NSInteger count = [maskRequest.results count];
			printf("Got %ld results (objects)\n", count);
			if (count>0)
			{
				VNInstanceMaskObservation * maskObservation = [maskRequest.results objectAtIndex:0];
				
				NSString * instanceMaskFilename = [NSString stringWithFormat:@"%@/mask.png", outputFolder];
				saveCVPixelBufferRef(maskObservation.instanceMask, instanceMaskFilename);
				printf("Wrote instance mask to: %s\n", [instanceMaskFilename UTF8String]);

				// Output the background
				outputMaskObservation(imageRequestHandler, maskObservation, 0, outputFolder);

				// For all observations output the image of the object related to the individual observation
				[maskObservation.allInstances enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop)
				 {
					outputMaskObservation(imageRequestHandler, maskObservation, idx, outputFolder);
				}];
			}
		}
	}];
	
	// Perform the request
	[imageRequestHandler performRequests:@[maskRequest] error:&error];
	if (error)
	{
		printf("Error performing request: %s\n", [[error description] UTF8String]);
		exit(-1);
	}
}

void createFolder(NSString * folderName)
{
	NSError * error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:folderName withIntermediateDirectories:YES attributes:nil error:&error];
	if (error)
	{
		printf("Error performing request: %s\n", [[error description] UTF8String]);
		exit(-1);
	}
}

int main(int argc, const char * argv[]) 
{
	@autoreleasepool 
	{
	    // insert code here...
		if (argc < 3)
		{
			printf("*** Error: Insufficient number of arguments on command line.\n\n");
			printf("Usage:\n");
			printf("\tMaskingTest [input filename] [output folder]\n\n");
			printf("\tWhere:\n");
			printf("\t\t[input filename]\t\tWill perform segmentation of this input file (jpg or png)\n");
			printf("\t\t[output folder] \t\tTarget folder where the files will be placed\n");
			exit(-1);
		}
		
		NSString * inputFilename = [NSString stringWithUTF8String:argv[1]];
		NSString * outputFolder = [NSString stringWithUTF8String:argv[2]];

		// Check that output folder exists
		BOOL directory = NO;
		if (![[NSFileManager defaultManager] fileExistsAtPath:outputFolder isDirectory:&directory] || !directory)
		{
			printf("Output folder %s does not exist. Creating.\n", [outputFolder UTF8String]);
			createFolder(outputFolder);
		}

		// GO!
		performMaskingOfImage(inputFilename, outputFolder);
	}
	return 0;
}
