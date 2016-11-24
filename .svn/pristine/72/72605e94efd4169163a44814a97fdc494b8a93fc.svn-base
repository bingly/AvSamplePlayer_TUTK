#include "colorconvert.h"

/****************************************************/
/* Sum the input */
/* Input: input, len */
/* Output: input */
/* Algorithm: add */
/****************************************************/
#define RGB_Y_OUT		1.164
#define B_U_OUT			2.018
#define Y_ADD_OUT		16

#define G_U_OUT			0.391
#define G_V_OUT			0.813
#define U_ADD_OUT		128

#define R_V_OUT			1.596
#define V_ADD_OUT		128


#define SCALEBITS_OUT	13
#define FIX_OUT(x)		((short) ((x) * (1L<<SCALEBITS_OUT) + 0.5))

static long int crv_tab[256];
static long int cbu_tab[256];
static long int cgu_tab[256];
static long int cgv_tab[256];
static long int tab_76309[256]; 
static unsigned char clp[1024]; //for clip in CCIR601


static int RGB_Y_tab[256];
static int B_U_tab[256];
static int G_U_tab[256];
static int G_V_tab[256];
static int R_V_tab[256];

void InitConvtTbl()
{
	long int crv,cbu,cgu,cgv;
	int i,ind; 

	{
		static int initialized = 0;

		if (initialized != 0)
			return;
		initialized = 1;
	}	
	
	crv = 104597; cbu = 132201; 
	cgu = 25675; cgv = 53279;	
	
	for (i = 0; i < 256; i++) 
	{
		crv_tab[i] = (i-128) * crv;
		cbu_tab[i] = (i-128) * cbu;
		cgu_tab[i] = (i-128) * cgu;
		cgv_tab[i] = (i-128) * cgv;
		tab_76309[i] = 76309*(i-16);

        RGB_Y_tab[i] = FIX_OUT(RGB_Y_OUT) * (i - Y_ADD_OUT);
		B_U_tab[i]   = FIX_OUT(B_U_OUT) * (i - U_ADD_OUT);
		G_U_tab[i]   = FIX_OUT(G_U_OUT) * (i - U_ADD_OUT);
		G_V_tab[i]   = FIX_OUT(G_V_OUT) * (i - V_ADD_OUT);
		R_V_tab[i]   = FIX_OUT(R_V_OUT) * (i - V_ADD_OUT);
	}

	for (i=0; i<384; i++)
		clp[i] =0;
	ind=384;
	for (i=0;i<256; i++)
		clp[ind++]=i;
	ind=640;
	for (i=0;i<384;i++)
		clp[ind++]=255;
}

void rgb24_to_i420(unsigned char *bmp,unsigned char *dst,int width,int height)
{
/* Same value than in XviD */
#define BITS 8
#define FIX(f) ((int)((f) * (1 << BITS) + 0.5))

#define Y_R   FIX(0.257)
#define Y_G   FIX(0.504)
#define Y_B   FIX(0.098)
#define Y_ADD 16

#define U_R   FIX(0.148)
#define U_G   FIX(0.291)
#define U_B   FIX(0.439)
#define U_ADD 128

#define V_R   FIX(0.439)
#define V_G   FIX(0.368)
#define V_B   FIX(0.071)
#define V_ADD 128

	unsigned char *src = bmp +  width * 3 * (height -1);
	int			  i_src = width * 3;	
	int			  stride = width;
		int     i_y  = stride; 

	unsigned char *y = dst;
	unsigned char *u = dst + (width * height);
	unsigned char *v = u + ( (width * height) >> 2);

	for(  ; height > 0; height -= 2 )              
	{                                                   
		unsigned char *ss = src;                              
		unsigned char *yy = y;                                
		unsigned char *uu = u;                                
		unsigned char *vv = v;                                
		int w;                                          

		for( w = width; w > 0; w -= 2 )               
		{                                               
			int cr,cg ,cb;                   
			int r, g, b;                                

			/* Luma */                                  
			cr = r = ss[2];                         
			cg = g = ss[1];                         
			cb = b = ss[0];                         

			yy[0] = Y_ADD + ((Y_R * r + Y_G * g + Y_B * b) >> BITS);    

			cr+= r = ss[2-i_src];                   
			cg+= g = ss[1-i_src];                   
			cb+= b = ss[0-i_src];                   
			yy[i_y] = Y_ADD + ((Y_R * r + Y_G * g + Y_B * b) >> BITS);  
			yy++;                                       
			ss += 3;                                

			cr+= r = ss[2];                         
			cg+= g = ss[1];                        
			cb+= b = ss[0];                         

			yy[0] = Y_ADD + ((Y_R * r + Y_G * g + Y_B * b) >> BITS);    

			cr+= r = ss[2-i_src];                   
			cg+= g = ss[1-i_src];                   
			cb+= b = ss[0-i_src];                   
			yy[i_y] = Y_ADD + ((Y_R * r + Y_G * g + Y_B * b) >> BITS);  
			yy++;                                       
			ss += 3;                                

			/* Chroma */                                
			*uu++ = (unsigned char)(U_ADD + ((-U_R * cr - U_G * cg + U_B * cb) >> (BITS+2)) ); 
			*vv++ = (unsigned char)(V_ADD + (( V_R * cr - V_G * cg - V_B * cb) >> (BITS+2)) ); 
		}                                               

		src -= 2*i_src;                                   
		y += 2*stride;                        
		u += stride/2;                          
		v += stride/2;                          
	}            	
}

static void i420_to_rgb24_r(unsigned char *Y,unsigned char *U,unsigned char *V, unsigned char *dst_ori,
				   int width,int height,int stride)
{
	unsigned char *src0;
	unsigned char *src1;
	unsigned char *src2;
	int y1,y2; 
	unsigned char *py1,*py2,*pyy1,*pyy2,*u,*v,*uu,*vv;
	int i,j, c1, c2, c3, c4;
	unsigned char *d1, *d2,*dd1, *dd2;

	//Initialization
	src0=Y; 
	src1=U;
	src2=V;

	py1=src0;
	py2=py1+stride;
	d1=dst_ori+3*width*(height-1);	
	d2=d1-3*width;
	//d1 = dst_ori;
	//d2 = dst_ori + 3*width;
	u=src1;
	v=src2;
	for (j = 0; j < height; j += 2) 
	{ 
		uu=u;
		vv=v;
		pyy1=py1;
		pyy2=py2;
		dd1=d1;
		dd2=d2;
		for (i = 0; i < width; i += 2) 
		{			
			c1 = crv_tab[*vv];
			c2 = cgu_tab[*uu];
			c3 = cgv_tab[*vv++];
			c4 = cbu_tab[*uu++];

			//up-left
			y1 = tab_76309[*pyy1++]; 
			*dd1++ = clp[384+((y1 + c4)>>16)]; 
			*dd1++ = clp[384+((y1 - c2 - c3)>>16)];
			*dd1++ = clp[384+((y1 + c1)>>16)];

			//down-left
			y2 = tab_76309[*pyy2++];
			*dd2++ = clp[384+((y2 + c4)>>16)]; 
			*dd2++ = clp[384+((y2 - c2 - c3)>>16)];
			*dd2++ = clp[384+((y2 + c1)>>16)];

			//up-right
			y1 = tab_76309[*pyy1++];
			*dd1++ = clp[384+((y1 + c4)>>16)]; 
			*dd1++ = clp[384+((y1 - c2 - c3)>>16)];
			*dd1++ = clp[384+((y1 + c1)>>16)];

			//down-right
			y2 = tab_76309[*pyy2++];
			*dd2++ = clp[384+((y2 + c4)>>16)]; 
			*dd2++ = clp[384+((y2 - c2 - c3)>>16)];
			*dd2++ = clp[384+((y2 + c1)>>16)];			
		}
		d1 -= 6*width;
		d2 -= 6*width;
		py1+= 2*stride;
		py2+= 2*stride;
		u  += stride/2;
		v  += stride/2;
	} 

}

//static void i420_to_rgb24(unsigned char *Y,unsigned char *U,unsigned char *V, unsigned char *dst_ori,
//				   int width,int height,int stride)
//{
//	unsigned char *src0;
//	unsigned char *src1;
//	unsigned char *src2;
//	int y1,y2; 
//	unsigned char *py1,*py2,*pyy1,*pyy2,*u,*v,*uu,*vv;
//	int i,j, c1, c2, c3, c4;
//	unsigned char *d1, *d2,*dd1, *dd2;
//
//	//Initialization
//	src0=Y; 
//	src1=U;
//	src2=V;
//
//	py1=src0;
//	py2=py1+stride;
//	//d1=dst_ori+3*width*(height-1);	
//	//d2=d1-3*width;
//	d1 = dst_ori;
//	d2 = dst_ori + 3*width;
//	u=src1;
//	v=src2;
//	for (j = 0; j < height; j += 2) 
//	{ 
//		uu=u;
//		vv=v;
//		pyy1=py1;
//		pyy2=py2;
//		dd1=d1;
//		dd2=d2;
//		for (i = 0; i < width; i += 2) 
//		{			
//			c1 = crv_tab[*vv];
//			c2 = cgu_tab[*uu];
//			c3 = cgv_tab[*vv++];
//			c4 = cbu_tab[*uu++];
//
//			//up-left
//			y1 = tab_76309[*pyy1++]; 
//			*dd1++ = clp[384+((y1 + c4)>>16)]; 
//			*dd1++ = clp[384+((y1 - c2 - c3)>>16)];
//			*dd1++ = clp[384+((y1 + c1)>>16)];
//
//			//down-left
//			y2 = tab_76309[*pyy2++];
//			*dd2++ = clp[384+((y2 + c4)>>16)]; 
//			*dd2++ = clp[384+((y2 - c2 - c3)>>16)];
//			*dd2++ = clp[384+((y2 + c1)>>16)];
//
//			//up-right
//			y1 = tab_76309[*pyy1++];
//			*dd1++ = clp[384+((y1 + c4)>>16)]; 
//			*dd1++ = clp[384+((y1 - c2 - c3)>>16)];
//			*dd1++ = clp[384+((y1 + c1)>>16)];
//
//			//down-right
//			y2 = tab_76309[*pyy2++];
//			*dd2++ = clp[384+((y2 + c4)>>16)]; 
//			*dd2++ = clp[384+((y2 - c2 - c3)>>16)];
//			*dd2++ = clp[384+((y2 + c1)>>16)];			
//		}
//		d1 += 6*width;
//		d2 += 6*width;
//		py1+= 2*stride;
//		py2+= 2*stride;
//		u  += stride/2;
//		v  += stride/2;
//	} 
//
//}

void i420_to_rgb24(unsigned char *src, unsigned char *dst, int width,int height)
{
	unsigned char *y;
	unsigned char *u;
	unsigned char *v;

	y = src;
	v = src + width * height;
	u = v + ( (width * height) >> 2 );

	i420_to_rgb24_r(y,u,v,dst,width,height,width);
}
