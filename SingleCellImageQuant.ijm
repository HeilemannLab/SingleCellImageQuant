// Created at 12/07/2023
// author: Claudia Catapano
// Research Group Heilemann
// Institute for Physical and Theoretical Chemistry, Goethe University Frankfurt am Main.

// loads 3-Channel 3D microscopy files and sums z-stacks
// uses the actin and DAPI channel to create regions of interest
// area and mean intensity are calculated for the region of interest in the protein channel 

requires("1.54f");

// clear up Fiji

// closes all open image windows
run("Close All"); 		
// if the ROI manager contains any ROIs, these are deleted beforehand 
if (roiManager("count") > 0) {
	roiManager("Select All");
	roiManager("Delete");
} 
// close open Log, Debug, Threshold, Results, ROI manager windows
close("ROI Manager");
run("Clear Results");
close("Results");
close("Log");
close("Debug");
close("Threshold");


// Dialog window for parameters choice
yesno = newArray("yes", "no");			// create array for choice between yes or no in dialog windows
thresholding = newArray("automatic", "manual");		// create array for choice between automatic or manual in dialog windows

// initiate dialog window for parameter choice
Dialog.create("Settings");

// set general settings (batch processing, results folder name)
Dialog.addChoice("batch process", yesno);		// default value is yes
Dialog.addMessage(" ");
Dialog.addString("results folder name", "results"); 	// default folder name is "results"
// set microscopy image file formats of the 3D stack supported by bioformats plugin
Dialog.addString("project file format", ".lif");
Dialog.addMessage("  ");

// prompts user input for channel settings
// define the channel order in files for actin, DAPI, and the protein of interest channels
Dialog.addString("DAPI channel", "1");
Dialog.addString("actin channel", "3");
Dialog.addString("protein of interest channel", "2");
Dialog.addMessage(" ");

// prompts user input for thresholding parameters
// define threshold method + parameters
Dialog.addChoice("thresholding for actin", thresholding);		// default value is automatic
Dialog.addString("lower threshold (set for manual thresholding only, 0-255)", 55);		// set lower threshold for all images, if "automatic" was chosen above
Dialog.addString("upper threshold (set for manual thresholding only, 0-255)", 255);		// set upper threshold for all images, if "automatic" was chosen above
Dialog.addNumber("Filter options for actin mask - Gaussian blur radius [px]", 2);		// set gaussian blur radius
Dialog.addNumber("Filter options for actin mask - Median", 2);		// set value for Median filtering
Dialog.addMessage(" ");

// prompts for analyzing cytoplasmic & nucleic signals
Dialog.addChoice("analyze cytoplasmic & nucleic signals (if yes, define threshold below)", yesno);	// default value is yes
Dialog.addChoice("thresholding for nuclei", thresholding);		// set thresholding method as above for nuclei detection
Dialog.addString("lower threshold (set for manual thresholding only, 0-255)", 20);		// set lower threshold as above for nuclei detection
Dialog.addString("upper threshold (set for manual thresholding only, 0-255)", 255);		// set upper threshold as above for nuclei detection
Dialog.addNumber("Filter options for nuclei mask - Median", 10);		// set value for Median filtering for nuclei, choose a rather high value
Dialog.addMessage(" ");

// displays instructions 
Dialog.addMessage("start macro by clicking ok and choose a file from the folder containing all project files that should be processed");

// shows the dialog box to the user.
Dialog.show();

// retrieving user inputs from the dialog box
batch = Dialog.getChoice;
resultsFolderName = Dialog.getString;
specificString = Dialog.getString;
dapiChannel = Dialog.getString;
actinChannel = Dialog.getString;
proteinChannel = Dialog.getString;	
thresholdMethodActin = Dialog.getChoice;
lowerThresholdActin = Dialog.getString;			
upperThresholdActin = Dialog.getString;
gaussianBlurRadiusActin = Dialog.getNumber;
medianRadiusActin = Dialog.getNumber;
ratio = Dialog.getChoice;
thresholdMethodDAPI = Dialog.getChoice;
lowerThresholdDAPI = Dialog.getString;			
upperThresholdDAPI = Dialog.getString;
medianRadiusNuclei = Dialog.getNumber;


//set the ROI measurement parameters
run("Set Measurements...", "area mean modal integrated limit display redirect=None decimal=9");	

// configures batch processing based on user selection.
if (batch=="yes") {
	setBatchMode(true);
} else {
	setBatchMode(false);
}


// loads in the data
run("Bio-Formats", "autoscale color_mode=Colorized open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT"); 		// opens the Bio-Formats dialog box to select a confocal image file. the user needs to select the file manually
dir = getDirectory("image"); 	// retrieves the directory path where the selected image is located.
fileList = newArray(0);			// creates an array to store the file names containing the specific string
list = getFileList(dir); 		// gets a list of all files in the directory

// creates a new results directory and neccessary subdirectories where the original images are located
File.makeDirectory(dir + "/" + resultsFolderName);
File.makeDirectory(dir + "/" + resultsFolderName + "/z_projections"); 
File.makeDirectory(dir + "/" + resultsFolderName + "/masks_actin"); 
File.makeDirectory(dir + "/" + resultsFolderName + "/rois_actin"); 
if (ratio=="yes") {
	File.makeDirectory(dir + "/" + resultsFolderName + "/rois_nuclei"); 
	File.makeDirectory(dir + "/" + resultsFolderName + "/masks_nuclei"); 
	File.makeDirectory(dir + "/" + resultsFolderName + "/rois_cytoplasm");
} else {
}

close("*");		// closes all open image files (to close the one to retrieve the file paths from step 3-7)


// Save the input parameters to a text file in the chosen results folder and clear up Fiji
print("Batch processing: " + batch);
print("DAPI Channel: " + dapiChannel);
print("Actin Channel: " + actinChannel);
print("Protein Channel: " + proteinChannel);
print("Thresholding for actin: " + thresholdMethodActin);
print("Lower Threshold to create masks of whole cells: " + lowerThresholdActin);
print("Upper Threshold to create masks of whole cells: " + upperThresholdActin);
print("Filtering options for actin mask - Gaussian blur radius [px]: " + gaussianBlurRadiusActin);
print("Filtering options for actin mask - Median: " + medianRadiusActin);
print("Analysis of cytoplasm and nuclei: " + ratio);
if (ratio=="yes") {
	print("Thresholding for the nuclei: " + thresholdMethodDAPI);
	print("Lower threshold to create masks of the nuclei: " + lowerThresholdDAPI);
	print("Upper threshold to create masks of the nuclei: " + upperThresholdDAPI);
	print("Filter options for nuclei mask - Median: " + medianRadiusNuclei);
	} else {
		}
selectWindow("Log");
path = dir + "/" + resultsFolderName + "/input_parameters.txt";
saveAs("Text", path);
close("Log");


// Loop through the list of files to find the ones with the specific string
for (i = 0; i < list.length; i++) {
  if (indexOf(list[i], specificString) >= 0) {
    fileList = Array.concat(fileList, list[i]);
  }
}


// create and save sumed z-projections for each image in all project files in the above chosen folder
for (i = 0; i < fileList.length; i++) {		// loops through the list of files and processes each file

	filePath = dir + fileList[i];		// constructs the full file path for the selected image from the list
	
	run("Bio-Formats", "open=filePath autoscale color_mode=Colorized open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");		// opens the image from the list

	for (series = 1; series <= nImages(); series++) {		// loops through all open images from a project file (= series)
	  selectImage(series);		// selects the current series
	  
	  // gets the title of the image without the file extension
	  title = getTitle();
	  titleWithoutExtension = File.getNameWithoutExtension(title);
	  
	  run("Z Project...", "projection=[Sum Slices]");		// executes z-projection with "sum slices" projection type
	  saveAs("OME-Tiff", dir + "/" + resultsFolderName + "/z_projections/" + title + ".tif");		// saves the z-projected image with the same name as it is created with
	  close();		// closes the current image to prepare for the next iteration
	}
	close("*");						 // closes all open images
}
	close("*");						 // closes all open images


// create and save masks of whole cells based on the actin channel
listResults = getFileList(dir + "/" + resultsFolderName + "/z_projections/");		// create list from all z-projections in the results folder
for (j = 0; j < listResults.length; j++) {		// loops through the saved z-projections to create masks of whole cells
    maskFilePath = dir + "/" + resultsFolderName + "/masks_actin/" + listResults[j] + "_actinmask.tif";		// constructs the output mask file path
    
    // checks if the mask file already exists, if yes, skip processing this file
    if (File.exists(maskFilePath)) {
        print("Mask already exists for: " + listResults[j] + ". Skipping...");
    } else {
		open(dir + "/" + resultsFolderName + "/z_projections/" + listResults[j]);		// opens z-projection from created list
		run("Arrange Channels...", "new=" + actinChannel);		// rearranges channels and deletes DAPI and protein channels
		run("8-bit"); 															// converts the current image to 8-bit (grayscale)

		// applies filters for better mask creation
		run("Enhance Contrast...", "saturated=0.01 equalize");
		run("Median...", "radius=" + medianRadiusActin);
		run("Gaussian Blur...", "sigma=" + gaussianBlurRadiusActin);

		// sets the threshold to include only pixels with intensity values between two values based on the user chosen parameters
		if (thresholdMethodActin=="automatic") {
			setThreshold(lowerThresholdActin, upperThresholdActin);
		} else if (thresholdMethodActin=="manual") {
			run("Threshold...");
			waitForUser("threshold", "select threshold > Apply before ok");
		}
		
		setOption("BlackBackground", true);		// specifies that background is considered black
		run("Convert to Mask", "method=Huang background=Dark black");		//  converts the image to a binary mask based on the threshold
		saveAs("Tiff", dir + "/" + resultsFolderName + "/masks_actin/" + listResults[j] +"_actinmask");		// saves the binary mask image to the "z_projections" directory
		run ("Create Selection");		// creates ROI from mask
		roiManager("Add");		// adds ROI to ROI Manager
		roiManager("Select", roiManager("Count") - 1);		// selects the latest added ROI
		roiManager("Rename", listResults[j]);		// renames the latest created ROI to the file name
		roiManager("Select", roiManager("Count") - 1);		// select the latest ROI	
		roiManager("Save", dir + "/" + resultsFolderName + "/rois_actin/" + listResults[j] + "_actin.roi");		// save the latest ROI with the respective name from the file list
		close("*");		// close latest image to prepare for the next iteration
	}
}


// create and save masks of nuclei based on the DAPI channel
if (ratio=="yes") {			// loops through the saved z-projections to create masks of nuclei if selected by the user
	listResults = getFileList(dir + "/" + resultsFolderName + "/z_projections/");		// create list from all z-projections in the results folder
	for (j = 0; j < listResults.length; j++) {		// loops through the saved z-projections to create masks of whole cells
		maskFilePath = dir + "/" + resultsFolderName + "/masks_nuclei/" + listResults[j] + "_nucleimask.tif";		// constructs the output mask file path
		
		// checks if the mask file already exists, if yes, skip processing this file
		if (File.exists(maskFilePath)) {
			print("Mask already exists for: " + listResults[j] + ". Skipping...");
		} else {
			open(dir + "/" + resultsFolderName + "/z_projections/" + listResults[j]);		// opens z-projection from created list
			run("Arrange Channels...", "new=" + dapiChannel);		// rearranges channels and deletes actin and protein channels
			run("8-bit");		// converts the current image to 8-bit (grayscale).

			// applies filters for better mask creation
			run("Median...", "radius=" + medianRadiusNuclei);
			run("Enhance Contrast...", "saturated=0.1");

			// sets the threshold to include only pixels with intensity values between two values based on the user chosen parameters
			if (thresholdMethodDAPI=="automatic") {
				setThreshold(lowerThresholdDAPI, upperThresholdDAPI);
			} else if (thresholdMethodDAPI=="manual") {
				run("Threshold...");
				waitForUser("threshold", "select threshold > Apply before ok");
			}
			
			setOption("BlackBackground", true);		// specifies that background is considered black
			run("Convert to Mask", "method=Huang background=Dark black");		//  converts the image to a binary mask based on the threshold
			saveAs("Tiff", dir + "/" + resultsFolderName + "/masks_nuclei/" + listResults[j] +"_nucleimask");		// saves the binary mask image to the "z_projections" directory
			run ("Create Selection");		// creates ROI from mask
			roiManager("Add");		// adds it to ROI Manager
			roiManager("Select", roiManager("Count") - 1);		// selects the latest added ROI
			roiManager("Rename", listResults[j]);		// renames the recently created ROI to the file name
			roiManager("Select", roiManager("Count") - 1); 		// selects the last added ROI
			roiManager("Save", dir + "/" + resultsFolderName + "/rois_nuclei/" + listResults[j] + "_nuclei.roi");		// saves the recently renamed ROI

			// cleans up ROI manager to prepare for cytoplasm mask creation
			roiManager("Select All");
			roiManager("Delete");
			
			// creates ROI of the cytoplasm
			roiManager("Open", dir + "/" + resultsFolderName + "/rois_actin/" + listResults[j] + "_actin.roi");		// opens ROI of whole cell (created from actin channel)
			roiManager("Open", dir + "/" + resultsFolderName + "/rois_nuclei/" + listResults[j] + "_nuclei.roi");		// opens ROI of nuclei (created from DAPI channel)
			roiManager("Deselect");		// deselects currently selected ROI to prepare for the next function
			roiManager("XOR");		// generates a new ROI excluding overlapping regions from both ROIS, i.e. of only the cytoplasm
			roiManager("Add");		// new ROI is added to the ROI manager
			count = roiManager("count");
			roiManager("select", count-1);		// selects latest ROI in the ROI manager
			roiManager("Save", dir + "/" + resultsFolderName + "/rois_cytoplasm/" + listResults[j] + "_cytoplasm.roi");		// save latest ROI of the cytoplasm
			close("*");  		// close open image to prepare for the next iteration
		}
	}
} else {		// if nuclei and cytoplasm should not be analyzed, nothing happens and the macro continues
}


// measure protein intensities in whole cells
listResults = getFileList(dir + "/" + resultsFolderName + "/z_projections/");		// creates a list from all z-projections
for (j = 0; j < listResults.length; j++) {			// measures and saves intensity of whole cells in the protein channel
    open(dir + "/" + resultsFolderName + "/z_projections/" + listResults[j]);		// opens a z-projection
 	run("Arrange Channels...", "new=" + proteinChannel);		// rearranges channels and deletes DAPI and actin channels
    open(dir + "/" + resultsFolderName + "/rois_actin/" + listResults[j] + "_actin.roi");		// opens the corresponding ROI file for the current z-projection
	run("Measure");		// measures within the ROI
	close("*");		// closes current image to prepare for the next iteration
	}


// saves results and cleans up Fiji
saveAs("Results", dir + "/" + resultsFolderName + "/" + "Results" + "_wholecell.txt");			// saves results from all analyzed files per run
roiManager("Select All");
roiManager("Delete");
run("Clear Results");


// measure protein intensities in nuclei
if (ratio=="yes") {		
	listResults = getFileList(dir + "/" + resultsFolderName + "/z_projections/");					// creates a list from all z-projections
	for (j = 0; j < listResults.length; j++) {			// loops through the saved z-projections to measure and save intensity of nuclei
	    open(dir + "/" + resultsFolderName + "/z_projections/" + listResults[j]);			// opens the tif file of a z-projection image
	 	run("Arrange Channels...", "new=" + proteinChannel);	    // rearranges channels and deletes DAPI and actin channels
	    open(dir + "/" + resultsFolderName + "/rois_nuclei/" + listResults[j] + "_nuclei.roi");			// opens the corresponding ROI file for the current z-projection image
		run("Measure");		// measures within the ROI
		close("*");			// close current image to prepare for the next iteration
		}
	saveAs("Results", dir + "/" + resultsFolderName + "/" + "Results" + "_nuclei.txt");			// saves results from all analyzed files
	run("Clear Results");		// cleans up results for the next loop
} else {		// if nuclei and cytoplasm should not be analyzed, nothing happens and the macro continues
}


// measure protein intensities in cytoplasm
if (ratio=="yes") {		
	listResults = getFileList(dir + "/" + resultsFolderName + "/z_projections/");		// creates a list from all z-projections			
	for (j = 0; j < listResults.length; j++) {			// loops through the saved z-projections to measure and save intensity of the cytoplasm
	    open(dir + "/" + resultsFolderName + "/z_projections/" + listResults[j]);			// opens the tif file of a z-projection image
	 	run("Arrange Channels...", "new=" + proteinChannel);	    // rearranges channels and deletes DAPI and actin channels
	    open(dir + "/" + resultsFolderName + "/rois_cytoplasm/" + listResults[j] + "_cytoplasm.roi");		// opens the corresponding ROI file for the current z-projection image
		run("Measure");		// measures within the ROI
		close("*");		// closes current image to prepare for the next iteration
		}
	saveAs("Results", dir + "/" + resultsFolderName + "/" + "Results" + "_cytoplasm.txt");			// saves results from all analyzed files
	run("Clear Results");		// cleans up results
} else {		// if nuclei and cytoplasm should not be analyzed, nothing happens and the macro continues
}

// close results table and show finish message
close("Results");		
waitForUser("Macro Finished!", "All files in the chosen directory were processed and the analysis is finished.");