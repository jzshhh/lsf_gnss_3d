# lsf_gnss_3d

# Attribution
lsf_gnss_3d is designed for extracting postseismic displacement form GNSS vertical position time series analysis based on the least squares fitting method. It is a modified version of Tsview software (http://www-gpsg.mit.edu/~tah/GGMatlab/#_tsview) (Herring, 2003)) and is suitable for batch processing of GNSS time series.

# Preparing some relevant files
When implementing this software, readers need to prepare some relevant files:

GNSS data file (.pos). The GNSS position time series at each station are saved in a single file (.pos) and all of them are placed in the folder (pbo/).
Offset data file (‘_break.neu’). The offset data files are saved in ‘_break.neu’ for each station and readers need to manually make these files. Different formats indicate different types of breakpoints, including instrumental offsets (e.g., 2011.37808219178 9999.99999999999 0 0), seismic offsets (e.g., 2011.37808219178 9999.99999999999 0 1), rate changes (e.g., 2011.37808219178 9999.99999999999 1 0), exponential postseismic term (e.g., 2011.37808219178 60 2 0) and logarithmic postseismic term (e.g., 2011.37808219178 9999.99999999999 60 1), note that the number 60 is relaxation time for postseismic deformation.

# To acknowledge use of this software, please cite some of following publications
Herring, T. (2003). MATLAB Tools for viewing GPS velocities and time series. GPS Solutions, 7, 194–199. doi: 10.1007/s10291-003-0068-0

Yuan, L.G., Ding, X.L., Chen, W., Simon, K., Chan, S.B., Hung, P.-S., Chau, K.-T., 2008. Characteristics of daily position time series from the Hong Kong GPS fiducial network. Chin. J. Geophys. 51, 1372–1384. Doi: 10.1002/cjg2.1292

Jiang, Z., Yuan, L., Huang, D., Yang, Z., Chen, W. 2017. Postseismic deformation associated with the 2008 Mw 7.9 Wenchuan earthquake, China: Constraining fault geometry and investigating a detailed spatial distribution of afterslip. Journal of Geodynamics 112, 12-21. Doi:10.1016/j.jog.2017.09.001

Jiang, Z., Yuan, L., Huang, D., Yang, Z., Hassan, A. 2018. Postseismic deformation associated with the 2015 Mw 7.8 Gorkha earthquake, Nepal: Investigating ongoing afterslip and constraining crustal rheology. Journal of Asian Earth Sciences 156, 1-10. Doi:10.1016/j.jseaes.2017.12.039

Jiang, Z., Huang, D., Yuan, L., Hassan, A., Zhang, L. Yang, Z. 2018 Coseismic and postseismic deformation associated with the 2016 Mw 7.8 Kaikoura earthquake, New Zealand: fault movement investigation and seismic hazard analysis. Earth, Planets and Space 70. Doi:10.1186/s40623-018-0827-3

Jiang, Z., Yuan, L., Huang, D., Zhang, L., Hassan, A. Yang, Z. 2018. Spatial-temporal evolution of slow slip movements triggered by the 2016 Mw 7.8 Kaikoura earthquake, New Zealand. Tectonophysics 744. Doi:10.1016/j.tecto.2018.06.012
