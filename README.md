## CRCF

Matlab implementation of "**Robust visual tracking with adaptive channel weighted color ratio feature**", with some improvements. HOG13 feature is modified from gradientMex.cpp of Piotr's toolbox. Due to the change of HOG13 feature implementation, the new feature weights are 0.3850, 0.3150 and 0.3 for gray, HOG13 and CR feature respectively. Code structure are borrowed from [martin-danelljan/ECO](https://github.com/martin-danelljan). 

Performance on OTB-2015 benchmark
![Precision plot of OPE](.\precision_plot.jpg)
![Success plot of OPE](.\success_plot.jpg)

### References

[1] Piotr Dollár.
"Piotr’s Image and Video Matlab Toolbox (PMT)."
Webpage: <https://pdollar.github.io/toolbox/>
GitHub: <https://github.com/pdollar/toolbox>
