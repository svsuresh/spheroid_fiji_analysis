// Run in batch mode (no UI display)
setBatchMode(true);

// Define the directory containing images
dir = "/Users/kumar/Desktop/test_images/";

// Define output directory for largest particle images
outDir = "/Users/kumar/Desktop/largest_particles/";
File.makeDirectory(outDir);  // Create directory if it doesn't exist

// Get list of files in the directory
list = getFileList(dir);

// Clear any previous results and ROI Manager
run("Clear Results");
roiManager("reset");

// Set measurements once at the beginning
run("Set Measurements...", "area mean min centroid perimeter bounding fit shape feret's redirect=None decimal=3");

// Loop through files
for (i = 0; i < list.length; i++) {
    // Open and process image
    open(dir + list[i]);
    imgName = getTitle();
    
    run("8-bit");
    run("Median...", "radius=5");
    run("Find Edges");
    setAutoThreshold("Otsu dark");
    
    // Analyze particles - this adds ROIs to ROI Manager
    run("Analyze Particles...", "size=0-Infinity circularity=0-1 show=Nothing add");
    
    // Get number of ROIs found in this image
    n = roiManager("count");
    
    if (n == 0) {
        print("No particles found in: " + list[i]);
        close();
        continue;
    }
    
    // Measure all ROIs to get their areas
    roiManager("Deselect");
    roiManager("Measure");
    
    // Find the largest particle from the measurements just added
    maxArea = 0;
    maxIndex = 0;
    startRow = nResults - n;  // Starting row for this image's particles
    
    for (j = 0; j < n; j++) {
        area = getResult("Area", startRow + j);
        if (area > maxArea) {
            maxArea = area;
            maxIndex = startRow + j;  // Absolute row index in Results table
        }
    }
    
    // Get the ROI index within the current batch
    roiIndexInBatch = maxIndex - startRow;
    
    // Select and save the largest particle
    roiManager("Select", roiIndexInBatch);
    run("Clear Outside");  // Keep only the largest particle
    
    // Save the image with largest particle
    saveAs("Tiff", outDir + list[i]);
    
    // Get all column headers from Results table
    numCols = 0;
    colNames = newArray();
    colValues = newArray();
    
    // Read all columns dynamically
    headings = split(String.getResultsHeadings(), "\t");
    for (k = 0; k < headings.length; k++) {
        if (headings[k] != " ") {  // Skip the row number column
            colNames = Array.concat(colNames, headings[k]);
            colValues = Array.concat(colValues, getResult(headings[k], maxIndex));
        }
    }
    
    // Clear all results from this image
    for (j = 0; j < n; j++) {
        IJ.deleteRows(nResults - 1, nResults - 1);
    }
    
    // Add back only the largest particle with all measurements
    row = nResults;
    for (k = 0; k < colNames.length; k++) {
        setResult(colNames[k], row, colValues[k]);
    }
    setResult("Label", row, list[i]);  // Use Label column for image name
    updateResults();
    
    // Clear ROI Manager for next image
    roiManager("reset");
    
    // Close the image
    close();
    call("java.lang.System.gc");
}

// Save the results table as CSV
if (nResults > 0) {
    saveAs("Results", "/Users/kumar/Desktop/measurements.csv");
    run("Close");  // Close the Results table
    print("Analysis complete! Results saved to: /Users/kumar/Desktop/measurements.csv");
    print("Total images processed: " + nResults);
} else {
    print("No particles were found in any images.");
}
setBatchMode(false);  // Exit batch mode