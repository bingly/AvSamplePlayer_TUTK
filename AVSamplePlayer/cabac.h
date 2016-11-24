
//#include <assert.h>

typedef struct CABACContext
{
    int low;
    int range;
    int outstanding_count;
    uint8_t lps_range[2*64][4];   ///< rangeTabLPS
    uint8_t lps_state[2*64];      ///< transIdxLPS
    uint8_t mps_state[2*64];      ///< transIdxMPS
    uint8_t *bytestream_start;
    uint8_t *bytestream;
    int bits_left;                ///<
}CABACContext;

extern const uint8_t ff_h264_lps_range[64][4];
extern const uint8_t ff_h264_mps_state[64];
extern const uint8_t ff_h264_lps_state[64];

void ff_init_cabac_decoder(CABACContext *c, uint8_t *buf, int buf_size);
void ff_init_cabac_states(CABACContext *c, uint8_t const (*lps_range)[4],
                          uint8_t const *mps_state, uint8_t const *lps_state, int state_count);

static inline void renorm_cabac_decoder(CABACContext *c)
{
    while(c->range < 0x10000)
	{
        c->range+= c->range;
        c->low+= c->low;
        if(--c->bits_left == 0)
		{
            c->low+= *c->bytestream++;
            c->bits_left= 8;
        }
    }
}

static inline int get_cabac(CABACContext *c, uint8_t * const state)
{
    int RangeLPS= c->lps_range[*state][((c->range)>>14)&3]<<8;
    int bit;

    c->range -= RangeLPS;
    if(c->low < c->range)
	{
        bit= (*state)&1;
        *state= c->mps_state[*state];
    }
	else
	{
        bit= ((*state)&1)^1;
        c->low -= c->range;
        c->range = RangeLPS;
        *state= c->lps_state[*state];
    }
    renorm_cabac_decoder(c);

    return bit;
}

static inline int get_cabac_static(CABACContext *c, int RangeLPS)
{
    int bit;

    c->range -= RangeLPS;
    if(c->low < c->range)
	{
        bit= 0;
    }
	else
	{
        bit= 1;
        c->low -= c->range;
        c->range = RangeLPS;
    }
    renorm_cabac_decoder(c);

    return bit;
}

static inline int get_cabac_bypass(CABACContext *c)
{
    c->low += c->low;

    if(--c->bits_left == 0)
	{
        c->low+= *c->bytestream++;
        c->bits_left= 8;
    }

    if(c->low < c->range)
	{
        return 0;
    }
	else
	{
        c->low -= c->range;
        return 1;
    }
}

static inline int get_cabac_terminate(CABACContext *c)
{
    c->range -= 2<<8;
    if(c->low < c->range)
	{
        renorm_cabac_decoder(c);
        return 0;
    }
	else
	{
        return c->bytestream - c->bytestream_start;
    }
}

static inline int get_cabac_u(CABACContext *c, uint8_t * state, int max, int max_index, int truncated)
{
    int i;

    for(i=0; i<max; i++)
	{
        if(get_cabac(c, state)==0)
            return i;

        if(i< max_index) state++;
    }

    return truncated ? max : -1;
}

static inline int get_cabac_ueg(CABACContext *c, uint8_t * state, int max, int is_signed, int k, int max_index)
{
    int i, v;
    int m= 1<<k;

    if(get_cabac(c, state)==0)
        return 0;

    if(0 < max_index) state++;

    for(i=1; i<max; i++)
	{
        if(get_cabac(c, state)==0)
		{
            if(is_signed && get_cabac_bypass(c))
                return -i;
			else
                return i;
        }

        if(i < max_index) state++;
    }

    while(get_cabac_bypass(c))
	{
        i+= m;
        m+= m;
    }

    v=0;
    while(m>>=1)
	{
        v+= v + get_cabac_bypass(c);
    }
    i += v;

    if(is_signed && get_cabac_bypass(c))
        return -i;
    else
        return i;
}
