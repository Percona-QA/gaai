-- gaai: Genetic Algorithm Artificial Intelligence Database Perfomance Tuning
-- Original work Copyright (c) 2017 Jérémy (Original Genetic Algorithm, MIT Licensed; ref LICENSE-OGA)
-- Original Genetic Algorithm: https://github.com/Mimyka/Genetic-Algorithm-Lua (revision: ccda781857b169aba54891f37f37a288636bead0)
-- Modified work Copyright (c) 2018 Roel Van de Paar, Percona LLC (Improvements, Database Performance Tuning, etc., GPLv2 Licensed)

-- Initial commit: GA optimized towards an EXPECTED_RESULT ("maximum") uses random numbers. Run like this: lua gaai.lua
-- This will be replaced soon with automated database tuning and will be integrated into Sysbench

EXPECTED_RESULT          = 9999999
MUTATION_CHANCE          = 0.05     -- How much % of genes to modify
GRADED_RETAIN_PERCENT    = 0.25     -- How much % to retain after chromosones have been graded (ranked)
NONGRATED_RETAIN_PERCENT = 0.05     -- How much % to retain of random individuals not in the top GRADED_RETAIN_PERCENT retained group
POPULATION_COUNT         = 100      -- Made up individuals (i.e. chromosones) which in turn are made up of genes (i.e. tuning params)
GENERATION_COUNT         = 100      -- How many generations (cycles)
CHROMOSOME_LENGTH        = 10       -- How many parameters to tune, i.e. how many genes
FAST_CONVERGENCE         = true     -- Fast convergence is ideal for intensive/slow optimization issues, but may hit local maxima
GRADED_RETAIN_COUNT      = POPULATION_COUNT * GRADED_RETAIN_PERCENT
MID_CHROMOSOME_LENGTH    = math.ceil(CHROMOSOME_LENGTH/2)

math.randomseed(os.time()*os.clock())  -- Random entropy pool init

local function randit()
  return math.random(0,EXPECTED_RESULT/CHROMOSOME_LENGTH)  -- Randum number from 0 to EXPECTED_RESULT divided by number of genes
end

local function choice(t)
  return t[math.random(1,#t)]  -- Return a random element from a table
end

local function get_random_individual()
  -- Return table of @CHROMOSOME_LENGTH
  local chromosome = {}
  for i = 1, CHROMOSOME_LENGTH do
     chromosome[i] = randit()   -- Set the genes one by one, creating an indvidual (i.e. a chromosome)
  end
  return chromosome
end

local function get_random_population()  -- Return table of @POPULATION_COUNT table of @CHROMOSOME_LENGTH 
  local population = {}
  for i = 0, POPULATION_COUNT do
    population[i] = get_random_individual()
  end
  return population
end

local function get_individual_solution(individual)
  local solution = 0
  for i = 1, CHROMOSOME_LENGTH do
    solution = solution + individual[i]
  end
  return solution
end

local function get_individual_fitness(individual)  -- Evaluate the fitness of an individual and return it
  local offset = math.abs(EXPECTED_RESULT-get_individual_solution(individual))
  if offset == 0 then 
    return 1  -- Perfect solution, there is no offset
  else
    return 1/offset  -- Return a value between almost-0 to almost-1 where 0 is worst and 1 is best
  end 
end

local function grade_population(population)
  -- Evaluate fitness of population
  local graded_population = {}
  for i=1,#population do
    graded_population[i] = {}
    graded_population[i][1] = population[i]
    graded_population[i][2] = get_individual_fitness(population[i])
  end
  table.sort(graded_population, function(a,b) return a[2] > b[2] end)
  return graded_population
end

local function evolve_population (population)
  -- Select almost best and a few random individual, crossover and mutate them
  local graded_population = grade_population(population)

  -- Select individuals to retain/reproduce in new generation
  local parents = {}
  for i=1,GRADED_RETAIN_COUNT do
    table.insert(parents, graded_population[i][1])
  end

  for i=GRADED_RETAIN_COUNT,#graded_population do
    if math.random() < NONGRATED_RETAIN_PERCENT then
      table.insert(parents, graded_population[i][1])
    end
  end

  -- Crossover parents to create children
  local desired_len = POPULATION_COUNT - #parents
  local children = {}
  while (#children < desired_len) do
      local child = {}
      local father = choice(parents)
      local mother = choice(parents)
      if father ~= mother then  -- father is not same individual as mother
        local parents = {father, mother}
        if FAST_CONVERGENCE then
          -- Mix genes of the child to one-by-one be those of either parent as selected randomly (leads to fast convergence)
          for i=1,CHROMOSOME_LENGTH do
            table.insert(child, parents[math.random(1,2)][i])
          end
        else
          -- Mix genes of child by taking half of father and half of mother, randomly first half or second half of their genes
          local a = math.random(1,2)
          local b = (function() if c == 1 then return 2 else return 1 end end)()
          for i=1,MID_CHROMOSOME_LENGTH do
            table.insert(child, parents[a][i])
          end
          for i=MID_CHROMOSOME_LENGTH,CHROMOSOME_LENGTH do
            table.insert(child, parents[b][i])
          end
        end
        table.insert(children, child)
      end
  end

  -- As a code optimization, instead of defining a new_population array or similar, just add the children to the parents array
  for i=1,#children do
    table.insert(parents, children[i])
  end

  -- Mutate some individuals (due to the code optimization above the parents+new children are in the parents array)
  for i=1,#parents do
    if math.random() < MUTATION_CHANCE then
      local gene_to_modify = choice(parents[i])
      parents[i][gene_to_modify]=randit()
    end
  end

  -- Regrade the entire population (due to the code optimization above the parents+new children are in the parents array)
  graded_population = grade_population(parents)

  local average_grade = 0
  for i=1,#graded_population do
    average_grade = average_grade + graded_population[i][2]
  end
  average_grade = average_grade / POPULATION_COUNT

  return parents, average_grade, graded_population
end

local function main ()
  -- Main loop and print result
  local population = get_random_population()
  local graded_population
  local actual_generation = 0
  local average_grade = false
  while (actual_generation < GENERATION_COUNT) do
    population, average_grade, graded_population = evolve_population(population)
    actual_generation = actual_generation + 1
    print('[' .. actual_generation .. " gen] - Average grade : " .. average_grade .. " (best:".. graded_population[1][2] .."|worst:".. graded_population[#graded_population][2] ..")")
  end

  print('-- Top solution -> ' .. EXPECTED_RESULT .. ' = ' .. get_individual_solution(graded_population[1][1]))
  print('Run took '..os.clock().."s")
end

main()
