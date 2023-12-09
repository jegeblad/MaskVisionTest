#import <Vision/Vision.h>
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>


// Helper -- Create a CGImage
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
	NSData *bitmapData;
	bitmapData = [resultImage representationUsingType:NSBitmapImageFileTypePNG properties:nil];
			[bitmapData writeToFile:targetFilename atomically:YES];
}


void performMaskingOfImage(NSString * filename)
{
	NSImage * img = [[NSImage alloc] initWithContentsOfFile:filename];
	NSBitmapImageRep * bitmap = (NSBitmapImageRep * )[img.representations objectAtIndex:0];
	CGImageRef cgImage = bitmap.CGImage;
	VNImageRequestHandler * imageRequestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
	NSError * error = nil;
	VNGenerateForegroundInstanceMaskRequest * maskRequest = [[VNGenerateForegroundInstanceMaskRequest alloc] initWithCompletionHandler:^(VNRequest * request, NSError * err)
	{
		NSLog(@"Completed reqestion... %@\n", request);
	
		if (err)
		{
			NSLog(@"Error: %@\n", [err description]);
		}
		
		if ([request isKindOfClass:[VNGenerateForegroundInstanceMaskRequest class]])
		{
			VNGenerateForegroundInstanceMaskRequest * maskRequest = (VNGenerateForegroundInstanceMaskRequest*)request;
			NSInteger count = [maskRequest.results count];
			NSLog(@"Got %ld results\n", count);
			if (count>0)
			{
				VNInstanceMaskObservation * maskObservation = [maskRequest.results objectAtIndex:0];
				
				saveCVPixelBufferRef(maskObservation.instanceMask, @"/Users/jegeblad/mask.png");
				NSLog(@"Instances: %@\n", maskObservation.allInstances);
				
				[maskObservation.allInstances enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
					NSIndexSet * iSet = [NSIndexSet indexSetWithIndex:0];
					CVPixelBufferRef  mask = [maskObservation generateMaskedImageOfInstances:iSet
													fromRequestHandler:imageRequestHandler
											  croppedToInstancesExtent:NO
																 error:nil];
					saveCVPixelBufferRef(mask, [NSString stringWithFormat:@"/Users/jegeblad/test_mask_%ld.png", idx]);
				}];
			}
		}
	}];
	[imageRequestHandler performRequests:@[maskRequest] error:&error];
	if (error)
	{
		NSLog(@"Erorr: %@\n", [error description]);
	}
	
}

int main(int argc, const char * argv[]) 
{
	@autoreleasepool {
	    // insert code here...
		performMaskingOfImage(@"/Users/jegeblad/StripDesigner_Strip.jpg");
	}
	return 0;
}
