// Duplicate and preprocess image
run("Duplicate...", "title=Duplicate_" + getTitle());
run("8-bit");
run("Median...", "radius=5");
run("Find Edges");
setAutoThreshold("Otsu dark");

// Analyze particles and add to ROI Manager
run("Analyze Particles...", "size=0-Infinity circularity=0-1 clear add");

// Find the largest particle
n = roiManager("count");
maxArea = 0;
maxIndex = 0;

for (i = 0; i < n; i++) {
    area = getResult("Area", i);
    if (area > maxArea) {
        maxArea = area;
        maxIndex = i;
    }
}

// Keep only the largest particle ROI
roiManager("Select", maxIndex);

// Get bounding box for cropping
getSelectionBounds(x, y, width, height);

// Reset ROI Manager and add the largest particle
roiManager("Reset");
roiManager("Add");

// Clear everything outside the largest particle
setBackgroundColor(0, 0, 0);
run("Clear Outside");

// Convert to red color (dark background with red particle)
run("Red");

// Crop to bounding box of largest particle
makeRectangle(x, y, width, height);
run("Crop");

// Measure the largest particle
// run("Clear Results");
run("Set Measurements...", "area mean min centroid perimeter bounding fit shape feret's redirect=None decimal=3");
roiManager("Measure");

// Garbage collection
run("Collect Garbage");

// Optional: Save the processed image
// saveAs("Tiff", "/Users/kumar/Desktop/" + getTitle() + "_largest.tif");

// Optional: Save measurements
// saveAs("Results", "/Users/kumar/Desktop/" + getTitle() + ".csv");
