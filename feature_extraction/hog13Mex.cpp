#include "mex.h"

void mexFunction(int nl, mxArray* pl[], int nr, mxArray* pr[])
{
    if(nl!=1) mexErrMsgTxt("Incorrect number of outputs!");
    
    const mwSize *dims = mxGetDimensions(pr[0]);
    const int rows = dims[0];
    const int cols = dims[1];
    const int channels = dims[3];
    
    mwSize outDims[3];
    int i,j,k;
    float* out = (float*)mxCalloc(rows*cols*13, sizeof(float));
    
    float* in = (float*)mxGetPr(pr[0]);
    pl[0] = mxCreateNumericMatrix(0,0,mxSINGLE_CLASS,mxREAL);
    outDims[0] = rows; outDims[1] = cols; outDims[2] = 13;
    mxSetData(pl[0],out); mxSetDimensions(pl[0],outDims,3);
    
    for(i=0;i<9;i++)
        for(j=0;j<rows*cols;j++)
        {
            for(k=0;k<4;k++)
                out[j+i*rows*cols]+=in[j+(i+k*9)*rows*cols];
        }
    
    for(i=0;i<4;i++)
        for(j=0;j<rows*cols;j++)
        {
            for(k=0;k<9;k++)
                out[j+(9+i)*rows*cols]+=in[j+(i*9+k)*rows*cols];
        }
}