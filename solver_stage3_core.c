#include <stdint.h>

enum {
    CUBIES = 7,
    PERMUTATIONS = 5040,
    ORIENTATIONS = 729,
    STATES = PERMUTATIONS * ORIENTATIONS,
    MOVES = 9,
    MAX_DEPTH  = 11
};

typedef struct {
    uint8_t p[CUBIES], o[CUBIES];
} state_t;

extern const uint16_t perm_R[PERMUTATIONS];
extern const uint16_t perm_B[PERMUTATIONS];
extern const uint16_t perm_D[PERMUTATIONS];

extern const uint16_t ori_R[ORIENTATIONS];
extern const uint16_t ori_B[ORIENTATIONS];
extern const uint16_t ori_D[ORIENTATIONS];


extern const uint8_t perm_distance[PERMUTATIONS];
extern const uint8_t ori_distance[ORIENTATIONS];

static const uint16_t *const permutation[3] = {
    perm_R, perm_B, perm_D
};

static const uint16_t *const orientation[3] = {
    ori_R, ori_B, ori_D
};

static uint8_t path[MAX_DEPTH + 1];

 static uint16_t mul_small(uint16_t x, uint8_t factor)
{
    switch (factor) {
    case 7:
        return (uint16_t)((x << 3) - x);       /* x * 7 */
    case 6:
        return (uint16_t)((x << 2) + (x << 1)); /* x * 6 */
    case 5:
        return (uint16_t)((x << 2) + x);       /* x * 5 */
    case 4:
        return (uint16_t)(x << 2);
    case 3:
        return (uint16_t)((x << 1) + x);
    case 2:
        return (uint16_t)(x << 1);
    default:
        return x;                              /* factor = 1 */
    }
}
static uint16_t rank_permutation(const state_t *state)
{
    uint16_t p = 0;

    for (uint8_t i = 0; i < CUBIES; ++i) {
        uint8_t smaller = 0;

        for (uint8_t j = (uint8_t)(i + 1U);
             j < CUBIES;
             ++j) {
            if (state->p[j] < state->p[i])
                ++smaller;
        }

        p = (uint16_t)(mul_small(p, (uint8_t)(CUBIES - i)) + smaller);
    }

    return p;
}

static uint16_t rank_orientation(const state_t *state)
{
    uint16_t o = 0;

    for (uint8_t i = 0; i < 6; ++i)
        o = (uint16_t)((o << 1) + o + state->o[i]);

    return o;
}


static int dfs_iterative(uint16_t start_p, uint16_t start_o,
                         uint8_t limit)
{
    typedef struct {
        uint16_t p, o;
        uint16_t next_p, next_o;
        int8_t previous_face;
        uint8_t face;
        uint8_t turn;
        uint8_t entered;
    } frame_t;

    frame_t stack[MAX_DEPTH + 1];
    uint8_t depth = 0;

    /* Root node */
    stack[0].p = start_p;
    stack[0].o = start_o;
    stack[0].previous_face = -1;
    stack[0].entered = 0;

    for (;;) {
        frame_t *f = &stack[depth];

        /*
         * Equivalent to entering recursive dfs().
         * This block is executed exactly once per node.
         */
        if (!f->entered) {
            f->entered = 1;

            /* Already solved */
            if (f->p == 0 && f->o == 0)
                return 1;

            uint8_t hp = perm_distance[f->p];
            uint8_t ho = ori_distance[f->o];
            uint8_t h = hp > ho ? hp : ho;

            /* Heuristic pruning */
            if ((uint8_t)(depth + h) > limit) {
                goto backtrack;
            }

            /* Reached depth limit */
            if (depth == limit)
                goto backtrack;

            /* Start exploring children */
            f->face = 0;
            f->turn = 0;
        }

        /*
         * Find the next child of this node.
         */
        for (;;) {
            /* All faces finished */
            if (f->face >= 3)
                goto backtrack;

            /* Do not turn the same face consecutively */
            if (f->face == (uint8_t) f->previous_face) {
                ++f->face;
                f->turn = 0;
                continue;
            }

            /* R/R2/R' finished for this face */
            if (f->turn >= 3) {
                ++f->face;
                f->turn = 0;
                continue;
            }

            /*
             * For the first turn of a face,
             * start from the parent state.
             */
            if (f->turn == 0) {
                f->next_p = f->p;
                f->next_o = f->o;
            }

            /*
             * Chained quarter turns:
             *
             * turn = 0 -> X
             * turn = 1 -> X2
             * turn = 2 -> X'
             */
            f->next_p = permutation[f->face][f->next_p];
            f->next_o = orientation[f->face][f->next_o];

            path[depth] =
                (uint8_t)(f->face * 3U + f->turn);

            uint8_t child_face = f->face;

            /*
             * Increment before descending so that,
             * after backtracking, the parent resumes
             * at the next turn.
             */
            ++f->turn;

            /* Push child */
            ++depth;

            stack[depth].p = f->next_p;
            stack[depth].o = f->next_o;
            stack[depth].previous_face = (int8_t) child_face;
            stack[depth].entered = 0;

            break;
        }

        continue;

backtrack:
        /*
         * Root exhausted -> no solution at this limit.
         */
        if (depth == 0)
            return 0;

        /* Pop current node */
        --depth;
    }
}

int solve_stage3(const state_t *state, uint8_t *solution_length)
{

    uint16_t start_p = rank_permutation(state);
    uint16_t start_o = rank_orientation(state);
    
    uint8_t hp = perm_distance[start_p];
    uint8_t ho = ori_distance[start_o];
    uint8_t start_limit = hp > ho ? hp : ho;

    for (uint8_t limit = start_limit;
         limit <= MAX_DEPTH;
         ++limit) {
        if (dfs_iterative(start_p, start_o, limit)) {
            *solution_length = limit;
            return 1;
}
    }
    return 0;
}
