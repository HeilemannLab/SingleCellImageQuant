# SingleCellImageQuant
Fast and automated processing of multi-channel 3D confocal microscopy data in Fiji<sup>[1]</sup>:
- 3D datasets are z-projected per channel
- create ROIs of full cells and nuclei based on two channels, e.g. DAPI and actin
- measure the intensity in and area of the ROI for each channel 

The pipeline is compatible with standard microscopy data formats working with the Bio-Formats importer<sup>[2]</sup> of Fiji.

![](tmp/SingleCellImageQuant_Workflow.png)

## To run the Plugin
- install Fiji v1.54f or higher according to the [documentation](https://imagej.net/software/fiji/downloads) 
- in Fiji navigate to Plugins → Macros → run
- insert settings and parameters
- choose a random file from a folder to batch process

Give the analysis a try with the file in the testdata folder.

## Contributors
Claudia Catapano, Marina Dietz

## Literature
[1] Schindelin, J., Arganda-Carreras, I., Frise, E. *et al.* Nat. Methods 9, 676–682 (2012).
[2] Linkert, M., Rueden, C. T., Allan, C., *et al.* J. Cell Biol., 189(5), 777–782 (2010).

## Citation
**Please cite our paper when using SPTAnalyser for your research.** 
Catapano, C., Dietz, M.S., Heilemann, M. *manuscript in prep.*
