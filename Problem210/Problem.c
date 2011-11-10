#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum
{
    OP_NOP = 0,
    OP_ASSIGNMENT,
    OP_PRINT,
    OP_LOCK,
    OP_UNLOCK,
    OP_END
} op_type_t;

typedef struct
{
    int var;    /* a: 0, b: 1, ..., z: 26 */
    int val;
} assignment_op_t;
 
typedef struct
{
    int var;
} print_op_t;

typedef struct
{
    op_type_t type;
    union
    {
        assignment_op_t assignment;
        print_op_t print;
    };
    
} instruction_t;

#define MAX_INST 25

typedef struct
{
    int id;
    
    instruction_t code[MAX_INST];
    int pc;
    
    int cycles;
    
} program_t;

#define MAX_PROGRAMS 5

typedef struct
{
    int vars[26];
    
    program_t* programs[MAX_PROGRAMS];
    
    program_t* blocked[MAX_PROGRAMS];
    program_t* ready[MAX_PROGRAMS];
    program_t* lock_owner;
    
    int time_quantum;
    int op_cycles[5];
    
} simulator_t;

void move_between_queue(program_t* prog, program_t* from[], program_t* to[])
{
    /* assume it is removed from the first position */
    memmove(from, from + 1, (MAX_PROGRAMS - 1) * sizeof(program_t*));
    from[MAX_PROGRAMS - 1] = NULL;
    
    /* add to the tail of new queue */
    if (to != NULL)
    {
        int i;
        for (i = 0; i < MAX_PROGRAMS; i++)
        {
            if (to[i] == NULL) 
            {
                to[i] = prog;
                break;
            }
        }
    }
}

int run_next_instruction(simulator_t* sim, program_t* prog)
{
    instruction_t* inst = &prog->code[prog->pc];
    
    switch (inst->type)
    {
    case OP_ASSIGNMENT:
        
        sim->vars[inst->assignment.var] = inst->assignment.val;
        break;
        
    case OP_PRINT:
        printf("%d: %d\n", prog->id, sim->vars[inst->print.var]);
        break;
        
    case OP_LOCK:
        if (sim->lock_owner != NULL) 
        {
            move_between_queue(prog, sim->ready, sim->blocked);
            return 0;
        }
        else {
            sim->lock_owner = prog;
        }
        break;
        
    case OP_UNLOCK:
        sim->lock_owner = NULL;
        if (sim->blocked[0]) {
            move_between_queue(sim->blocked[0], sim->blocked, sim->ready);
        }
        break;
        
    case OP_END:
        move_between_queue(prog, sim->ready, NULL);
        free(prog);
        return 0;
        
    default:
        break;
    }

    prog->pc++;
    prog->cycles += sim->op_cycles[inst->type - 1];
    return 1;
}

void run_simulator(simulator_t* sim)
{
    while (sim->ready[0] != NULL)
    {
        program_t* prog = sim->ready[0];
        prog->cycles = 0;
        
        while (run_next_instruction(sim, prog))
        {
            if (prog->cycles >= sim->time_quantum)
            {
                move_between_queue(prog, sim->ready, sim->ready);
                break;
            }
        }
    }
}

program_t* new_program(int id)
{
    program_t* prog;
    
    prog = malloc(sizeof(program_t));
    prog->id = id;
    prog->pc = 0;
    
    return prog;
}

int main(int argc, char* argv[])
{
    FILE* fp;
    int i, j, k;
    int cases;
    char input[256];
    
    if (argc < 2 || (fp = fopen(argv[1], "rt")) == NULL){
        return -1;
    }
    
    fgets(input, 256, fp);
    sscanf(input, "%d", &cases);
    
    fgets(input, 256, fp);
    
    for (i = 0; i < cases; i++)
    {
        int num_programs;
        simulator_t sim;
        memset(&sim, 0, sizeof(sim));
        
        fgets(input, 256, fp);
        sscanf(input, "%d %d %d %d %d %d %d", 
            &num_programs, 
            &sim.op_cycles[0],
            &sim.op_cycles[1],
            &sim.op_cycles[2],
            &sim.op_cycles[3],
            &sim.op_cycles[4],
            &sim.time_quantum);

        for (j = 0; j < num_programs; j++)
        {
            sim.ready[j] = sim.programs[j] = new_program(j + 1);
            
            for (k = 0; ; k++)
            {
                instruction_t* inst;
                
                inst = &sim.programs[j]->code[k];
                
                fgets(input, 256, fp);
                if (strncmp(input, "print", 5) == 0)
                {
                    char* var;
                    inst->type = OP_PRINT;
                    
                    var = strtok(input + 5, " \t\n");
                    inst->print.var = var[0] - 'a';
                }
                else if (strncmp(input, "lock", 4) == 0)
                {
                    inst->type = OP_LOCK;
                }
                else if (strncmp(input, "unlock", 6) == 0)
                {
                    inst->type = OP_UNLOCK;
                }
                else if (strncmp(input, "end", 3) == 0)
                {
                    inst->type = OP_END;
                }
                else
                {
                    char* var;
                    
                    inst->type = OP_ASSIGNMENT;
                    var = strtok(input, " \t\n");
                    inst->assignment.var = var[0] - 'a';
                    
                    strtok(NULL, " \t\n");
                    inst->assignment.val = atoi(strtok(NULL, " \t\n"));
                }
                
                if (inst->type == OP_END) {
                    break;
                }
            }
        }
        
        run_simulator(&sim);
    }
    
    return EXIT_SUCCESS;
}
