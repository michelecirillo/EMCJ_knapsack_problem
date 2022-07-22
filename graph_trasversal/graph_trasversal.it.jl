### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 656ea700-045a-11ed-095e-41d8aa67b9af
using Graphs, Plots, PlutoUI, GraphPlot, Colors, DataFrames, Compose

# ╔═╡ e4fefa2f-404f-4034-9744-b1ce8592f52e
using DataStructures, SimpleWeightedGraphs

# ╔═╡ 671e7283-7ff4-497a-afcc-ca1eb1d43591
begin
	# g = smallgraph(:karate)
	# g = smallgraph(:house)
	g = smallgraph(:frucht)
	locs_x, locs_y = spring_layout(g)
end

# ╔═╡ 7c8c95be-4e4b-4bf3-b541-7e73abf02bd2
begin
	# Struttura utile per creare le animazioni delle visiste
	mutable struct Search
		g::Union{AbstractGraph, AbstractSimpleWeightedGraph}
		root::Int
		search_tree::DiGraph
		borders::Vector{Vector}
		visit_order::Vector
		Search(g::Union{AbstractGraph, AbstractSimpleWeightedGraph}, root::Int) = new(g, root, SimpleDiGraph(nv(g)), Vector[], Int[])
	end

	function  add_step!(s::Search, nodes::Vector, from::Int)
		push!(s.visit_order, from)
		push!(s.borders, nodes)
	end
end

# ╔═╡ 26101d0d-05c8-46db-9371-a68ec9a7382d
begin
	using Random

	function random_DFS(G::AbstractGraph, root::Int)::Search
		search = Search(G, root)
		add_step!(search, [root], root)
		
		S = Int[]
		push!(S, root)
		isExplored = Dict(vertices(G) .=> false)
		isExplored[root] = true
		
		while !isempty(S)
			u = pop!(S)
			border = []
			neighs = shuffle(neighbors(G, u))
			for v ∈ neighs
				if !isExplored[v]
					isExplored[v] = true
					push!(S, v)
					push!(border, v)
					add_edge!(search.search_tree, u, v)
				end
			end
			add_step!(search, border, u)
		end
		search
	end
end

# ╔═╡ dad001a0-ff58-4a62-8e2a-97ecfd8a491d
md"""
# Visite su Grafi
In *informatica*, uno dei problemi più studiati è la **visita su grafi**, ovvero il processo di visita dei nodi di ung grafo.

Più formalmente, dato un grafo $G (V, E)$ e un nodo **sorgente** $s \in V$, si vuole trovare un **albero** $T \subseteq E$ composto dai *camminimi* (non necessariamente minimi) che partono da $s$ e raggiungono tutti gli altri nodi.

Osservare che se $G$ è disconnesso allora $T$ non sarà **ricoprente**, ovvero non tutti i nodi faranno parte del sottografo indotto da $T$.
"""

# ╔═╡ 4b01c4be-ce31-4bf8-88b5-ce46070d986f
md"""
## Casi d'uso
Le visite su grafi sono utili per svariate applicazioni.
Per esempio è molto utile per orientarsi su una mappa.

Se modelliamo una mappa con un grafo dove i nodi rappresentano gli incroci e gli archi le strade tra due incroci vicini, con una visita su questo grafo siamo in grado di identificare un percorso da un qualsiasi punto `A` a un qualsiasi punto `B` della mappa.

Inoltre se sappiamo che $T$ è composto da soli **cammini minimi** (diremo che $T$ è uno *shortest-path-tree* SPT) saremo certi che il percorso da `A` a `B` sarà ottimo.

Un altro problemma classico è la **risoluzione di un labirinto**, il quale saremo interessati a trattare in questo notebook.

Come primo, è possibile modellizare un labirinto come un grafo.
In tale grafo abbiamo un nodo per ogni bivio nel labirinto, più due nodi speciali: uno per l'**entrata** e uno per l'**uscita**.

Infine per ogni corridoio del labirinto inseriamo un arco che collega i rispettivi incroci/nodi.

	Come possiamo fuggire del labirinto?

Semplice, effettuando una visita partendo dal *nodo entrata* e vedere quale cammino conduce al **nodo uscita**.
"""

# ╔═╡ e5bb9db5-2708-449a-a0ca-06daf96dba1d
md"""
## BFS - Visita in ampiezza
Nella **visita in ampiezza** (**breadth-first-search** o in breve **BFS**), i nodi sono visitati in ordine **non decrescente** di distanza dalla sorgente $s$.

Fissiamo una sorgente $s \in V$ e sia $d_G(s, v)$ la **distance** del nodo $v$ dalla sorgente $s$ in $G$, per ogni nodo $v \in V$.

Il primo nodo visitato in una visita BFS è la sorgente $s$, perché $d_G(s, s) = 0$.
Succesivamente ogni nodo vicino $v \in N(s)$ (ovvero tutti nodi a distanza $d_G (s, v) = 1$) verranno visitati, dove appunto $N(s)$ indica il **vicinato** del nodo $s$.
Dopodiché verranno visitati tutti i *vicini dei vicini* di $s$, ovvero tutti i nodi a distanza $d_G (s, v) = 2$.

E così via...
"""

# ╔═╡ 2ce9ffd9-594a-4325-b293-89caea578263
md"""
Il funzionamento dell'algoritmo è descritto in seguito.
- creare una **coda** $Q$.
- contrassegnare $s$ come **visitata** ed inserirla in $Q$.
- finche la coda $Q$ non risulta vuota:
   - rimuovere l'ultimo elemento $u$ ($u$ = dequeue($Q$)).
   - per ogni vicino $v$ di $u$:
      - se $v$ non risulta già visitato:
         - contrassegnare $v$ come visitato.
         - inserirlo nella coda $Q$ ($Q$.enqueue($v$)).
         - porre $v$ *"figlio"* di $u$ nell'albero $T$.
"""

# ╔═╡ 4d3147fd-09fc-4a18-b7ae-3ca3a622013e
md"""
La complessità temporale di tale algoritmo risulta $O(|V| + |E|)$, perché:
- ogni nodo è prima inserito e poi rimosso dalla coda $Q$ una volta (nessuna volta se $G$ è disconnesso). Dato che le operazioni di inserimento e rimozione dalla coda richiedono tempo costante avremo un contributo di $O(|V|)$.
- per ogni nodo $u$ visitato, ogni suo vicino $v$ (ovvero ogni suo arco incidente) verrà osservato per determinare se $v$ è già stato visitato o meno. Avremo quindi un contributo di $\sum_{v \in V} \deg(v) \in O(|E|)$.

Sommando i singoli contributi avremo una complessità temporale di $O(|V|+|E|)$.
"""

# ╔═╡ 888f8c53-08dd-489c-9902-36874ad8d96b
root = 1

# ╔═╡ 9457c3fc-7e83-486f-84b6-30a42697b6f1
"""
	Visita in ampiezza.
Arguments:
- `G::AbstractGraph` the graph
- `root::Int64` the root node where the search starts
Output:
- `search::Search` the result of the BFS
"""
function BFS(G::AbstractGraph, root::Int)::Search
	# inizializzo la struttura dati che terrà traccia dello stato dilla visita
	search = Search(G, root)
	add_step!(search, [root], root)

	# inizializzo una coda Q
	Q = Int[]
	# inserisco la radice in coda
	pushfirst!(Q, root)
	# contrassegno tutti i nodi come non visitati
	isExplored = Dict(vertices(G) .=> false)
	# contrassegno tutti la radice come visitata
	isExplored[root] = true

	
	while !isempty(Q)
		# rimuovo il primo elemento dalla cada (dequeue)
		u = pop!(Q)
		border = []

		# per ogni vicino v di u, se esso non risulta già visitato, lo inserisco in coda, lo contrassegno come visitato e rendo v figlio di u nell'albero della visita BFS
		for v ∈ neighbors(G, u)
			if !isExplored[v]
				# contrassegno v come visitato
				isExplored[v] = true
				# inserisco v in coda
				pushfirst!(Q, v)
				
				push!(border, v)
				# rendo v figlio di u nell'albero della visita BFS
				add_edge!(search.search_tree, u, v)
			end
		end
		add_step!(search, border, u)
	end
	search
end

# ╔═╡ 9d0fd8e0-85b0-41ac-baaa-fa2bf0c9265d
"""
	plot_search
Funzione che mostra lo stato della visita `search` al tempo `t`.
"""
function plot_search(
	search::Search,
	t::Int;
	locs_x=locs_x,
	locs_y=locs_y,
	nodelabel=nothing,
	nodestrokelw=1,
	nodestrokec=colorant"black",
	edgestrokec=:default,
	EDGELABELSIZE=5,
	arrowlengthfrac=0
	)
	
	g = search.g
	visit = search.borders
	@assert 1 ≤ t ≤ length(visit) "time $t invalid"

	visited = search.visit_order[begin:t-1]
	border = append!([], visit[begin:t]...) |> Set |> collect
	#unvisited = append!([], visit[t+1:end]...)

	#membership = ones(Int, nv(g))
	membership = fill(3, nv(g))
	membership[border] .= 2
	membership[visited] .= 1
	#membership[unvisited] .= 3

	if t ≠ 1
		membership[search.visit_order[t]] = 4
	end
	
	nodecolor = [colorant"green", colorant"red", colorant"lightblue", colorant"purple"]
	nodefillc = nodecolor[membership]

	weights = []
	edge_color = edgestrokec
	if typeof(g) <: SimpleWeightedGraph && edgestrokec == :default
		weights = edges(g) |> collect .|> weight
		edge_color=colorant"lightgray"
	elseif edgestrokec == :default
		edge_color = colorant"black"
	end
	
	gplot(
		g, locs_x, locs_y,
		nodefillc=nodefillc,
		nodelabel=nodelabel,
		nodestrokec=nodestrokec,
		nodestrokelw=nodestrokelw,
		edgestrokec=edge_color,
		edgelabel=weights,
		EDGELABELSIZE=EDGELABELSIZE,
		arrowlengthfrac=arrowlengthfrac
	)
	
end

# ╔═╡ 67c43de2-9314-4538-9a4c-a04d7af4fe83
function plot_search_tree(search::Search; x::Vector=[], y::Vector=[])
	if isempty(x) || isempty(y)
		return gplot(search.search_tree, nodelabel=1:nv(search.search_tree), nodefillc="white", nodestrokec=colorant"black", nodestrokelw=1, edgestrokec="black")
	else
		return gplot(search.search_tree, x, y, nodelabel=1:nv(search.search_tree), nodefillc="white", nodestrokec=colorant"black", nodestrokelw=1, edgestrokec="black")
	end
end

# ╔═╡ 6f568adb-8348-4fe5-8111-8704305a5782
DataFrame(
	(color = [colorant"purple", colorant"red", colorant"green", colorant"lightblue"],
	state=["nodo corrente", "frontiera", "visitato", "inesplorato"])
)

# ╔═╡ 580c8d80-b941-4697-8331-448f858374a4
bfs_search = BFS(g, root)

# ╔═╡ 9ca87661-e5b9-4cd1-beb1-e7eb2a41d5ea
md"""
 time $(@bind t₁ Slider(1:length(bfs_search.borders), default=1, show_value=true))
"""

# ╔═╡ 30950c0f-fb6e-48ca-b533-906499be505f
plot_search(bfs_search, t₁, nodelabel=1:nv(g))

# ╔═╡ acc19bba-dc4f-47b8-b920-b3b8bb847aa7
md"> **Osservazione:** per grafi *non pesati* la visita *BFS* genera sempre uno *SPT*."

# ╔═╡ 175b272f-601e-4b67-a8d7-cfaf115b88b2
md"""
## DFS - Visita in profondità
Nella **visita in profondità** (**depth-first-search** o in breve **DFS**) si procede avanti nella visita, *da vicino in vicino*, finché possibile, ovvero finché non si incontrano più nodi inesplorati.

Una volta arrivati a un punto in cui non si può più procedere, si ritorna indientro proseguendo per altre strade inesplorate. 

Il funzionamento di tale algoritmo è davvero **molto simile** alla visita BFS, con la sola differenza che invece di usare una coda $Q$, si fa uso di una pila $S$.
"""

# ╔═╡ 02292df4-40c6-44c3-8515-3cb7d18b0283
md"""
Perciò il funzionamento è il seguente:
- creare una pila $S$.
- contrassegna $s$ come **visitato** e inseriscilo in $S$.
- finchè la pila non risulta vuota:
   - rimuovere il primo elemento $u$ in cima a $S$ ($u$ = pop($S$)).
   - per ogni vicino $v$ di $u$:
      - se $v$ non risulta già visitato:
         - contrassegnare $v$ come visitato.
         - inserirlo in cima alla pila $S$ ($S$.push($v$)).
         - porre $v$ *"figlio"* di $u$ nell'albero $T$.
"""

# ╔═╡ 9c3e4a77-9fa3-4f55-9486-0a1bf05249e3
md"Dato che le operazioni sono praticamente identiche alla visita BFS, la *complessità temporale* della visita DFS è $O(|V| + |E|)$."

# ╔═╡ 73077b44-6d0b-4641-a3ef-bf7d00a5dcfe
function DFS(G::AbstractGraph, root::Int)::Search
	# inizializzo la struttura dati che terrà traccia dello stato dilla visita
	search = Search(G, root)
	add_step!(search, [root], root)

	
	# inizializzo una pila S
	S = Int[]
	# inserisco la radice in coda
	push!(S, root)
	# contrassegno tutti i nodi come non visitati
	isExplored = Dict(vertices(G) .=> false)
	isExplored[root] = true
	
	while !isempty(S)
		# rimuovo l'elemento in cima alla pila S
		u = pop!(S)
		border = []

		# per ogni vicino v di u, se esso non risulta già visitato, lo inserisco in cima alla pila, lo marco come visitato e lo rendo figlio di u nell'albero della visita DFS
		for v ∈ neighbors(G, u)
			if !isExplored[v]
				isExplored[v] = true
				push!(S, v)
				push!(border, v)
				add_edge!(search.search_tree, u, v)
			end
		end
		add_step!(search, border, u)
	end
	search
end

# ╔═╡ d74053b1-b5d8-4eed-8832-b722b35e1926
dfs_search = DFS(g, root)

# ╔═╡ 434091e0-3db7-4cd6-ac13-6f6f5a803ac1
md"""
 time $(@bind t₂ Slider(1:length(dfs_search.borders), default=1, show_value=true))
"""

# ╔═╡ 86f19fb9-125a-443d-aa8c-fcee8b3ba951
plot_search(dfs_search, t₂, nodelabel=1:nv(g))

# ╔═╡ cfb9c99a-2ca2-4b3e-96d7-e203c92baf2b
md"> **Osservazione:** i cammini dell'albero della visita *DFS* non sono necessariamente sempre minimi."

# ╔═╡ 8ac046aa-f817-499c-8688-cc734b472c78
md"""
## Cammini minimi su grafi pesati - Algoritmo di Dijkstra
Un algoritmo più sofisticato rispetto ai precedenti è l'**algoritmo di Dijkstra**.

Questo algoritmo consente di calcolare lo *shortest-path-tree* radicaato in $s$ anche per **grafi pesati** $G(V, E, w: E \to \mathbb{R}^+)$, assumendo che i pesi siano tutti **non negativi**!

L'idea di base dell'algoritmo è *semplice ed elegante*.
In ogni momento manteniamo un insieme $S$ per il quale le distanza $d(u) := d_G(s,v)$ dei suoi elementi sono noti.

*Ad ogni passo* inseriamo il nodo inesplorato $v$ il quale **minimizza** la distanza da $S$, ovvero

$$v = \arg \min_{v \in V \setminus S} \{ d_G(S,v)\}$$

dove

$$d_G(S,v) = \min \{ d(u,v) : u \in S \} \;\; \forall S \subset V$$
"""

# ╔═╡ eb87622b-87e1-4366-95d1-d29fb4540224
md"""
Più precisamente, l'algoritmo funziona come segue:
- Mantenere un inseme $S$ di **nodi esplorati**, per i quali è determinata la distanza $d(u)$ da $s$ a $u$.
- Inizializzare $S = \{ s \}$ e porre $d(s) = 0$.
- Ripetutamente scegliere il nodo $v$ che massimizza
$$\pi^*(v) = \min_{e = (u,v) : u \in S} d(u) + w(e)$$
- Porre $d(v) = \pi^*(v)$ e aggiungere $v$ ad $S$.
- Se necessario, tenere traccia del *"nodo padre"* di $v$ (ovvero $u$).
"""

# ╔═╡ b47c9ec0-8d85-4b6b-87c9-54a06ebc22c3
md"""
Per tenere traccia in maniera efficiente delle distanze dei nodi faremo uso di una famosa struttura dati: la **coda con priorità**.

Sia quindi $PQ$ una coda con priorità, dove le **chiavi** sono i nodi e i **valori** sono le stime delle **distanza** da $s$.

Inizialmente i nodi al di fuori di $S$ avranno come stima $d(v) = \infty$, perciò $PQ\left[ v \right] = \infty$, invece $PQ\left[ s \right] = 0$.

Ogni volta che un nodo $v$ con **valore minimo** è rimosso, saremo certi che il suo valore $PQ\left[ v \right]$ minimizzerà $\pi^*(v)$

$$\pi^*(v) = \min_{e = (u,v) : u \in S} d(u) + w(e)$$

perciò potrà essere inserito in $S$.

Dopo ciò, per ogni vicino $x$ di $v$, noi possiamo aggiornare il valore di $x$ (ovvero la stima $d(x)$) come segue:
- se $d(v) + w((v, x)) \leq PQ \left[x \right]$ allora poni $PQ \left[x \right] = d(v) + w((v, x ))$.
- altrimenti lascia $PQ \left[x \right]$ invariato.

Quando $PQ$ risulterà vuoto, avremo finito!
"""

# ╔═╡ 254643d0-5e86-4722-96e5-5bc7940d8ac8
md"""
Calcolare la complessità di tale algoritmo risulta più articolato...

Se la coda con priorità è implementata con **heap binomiale**, ogni operazione necessaria (**inserire un elemento**, **rimuovere il minimo** e **aggiornare i valori**) sono eseguiti in tempo *logaritmico* $O(\log{n})$.

Pericò:
- ogni nodo è inserito e rimosso una volta (al più una se $G$ è disconnesso). Quindi verranno eseguite $O(|V|)$ operazioni di inserimento e $O(|V|)$ operazioni di rimozione del minimo.
- il valore del nodo $v$ può essere aggiornato al più una volta per ogni suo arco incidente, quindi verranno eseguite $O(|E|)$ operazioni di aggiornamento dei valori.

In conclusione la complessità risulta essere $O\left((|V| + |E|)\log{|V|}\right)$.
Se assumiamo che $G$ è connesso allora avremo che $|E| \in \Omega(|V|)$, e quindi un tempo di $O(|E| \log{|V|})$.
"""

# ╔═╡ 5705e51c-1752-4acd-8a11-6e7afaed0867
begin 
	wg = SimpleWeightedGraph(g)
	ε = 0.1
	for e ∈ edges(g)
		wg.weights[e.src, e.dst] = wg.weights[e.dst, e.src] = round(rand()*10+ε, digits=1)
	end
	wg
end

# ╔═╡ 8d042281-61b2-4cf2-8f0f-4f42f0fb4050
begin
	function Dijkstra(G::AbstractSimpleWeightedGraph, root::Int)
		search = Search(G, root)
		
		dist = fill(Inf, nv(G))
		prev = fill(-1, nv(G))
		PQ = PriorityQueue(1:nv(G) .=> Inf)
	
		PQ[root] = 0
		dist[root] = 0
	
		while !isempty(PQ)
			u = dequeue!(PQ)
			border = [u]
			for v ∈ neighbors(G, u)
				push!(border, v)
				if v ∈ keys(PQ) && dist[u] + G.weights[u,v] ≤ dist[v]
					dist[v] = dist[u] + G.weights[u,v]
					PQ[v] = dist[u] + G.weights[u,v]
					prev[v] = u
				end
				add_step!(search, border, u)
			end
		end
	
		return (dist, prev, search)
	end

	Dijkstra(G::Graph, root::Int) = Dijkstra(SimpleWeightedGraph(G), root)
	Dijkstra(G::DiGraph, root::Int) = Dijkstra(SimpleWeightedDiGraph(G), root)
end

# ╔═╡ 826b1e26-36b8-4ba9-a535-b49600536526
dist, prev, dijkstra_search = Dijkstra(wg, 1)

# ╔═╡ b52b3a7b-a953-4d9f-9b00-6fd28714d20c
md"""
 time $(@bind t₃ Slider(1:length(dijkstra_search.borders), default=1, show_value=true))
"""

# ╔═╡ 79d11ee0-24f7-44ac-aae8-655255e76dcf
plot_search(dijkstra_search, t₃, nodelabel=1:nv(g))

# ╔═╡ 86210bf9-b85d-419a-ac4f-3cc8a7babc3f
function plot_search_tree(prev::Vector)
	g = DiGraph(length(prev))
	for v=1:nv(g)
		u = prev[v] 
		if u ≠ -1
			add_edge!(g, u, v)
		end
	end
	
	gplot(
		g,
		nodelabel=1:nv(g),
		nodefillc="white",
		nodestrokec=colorant"black",
		nodestrokelw=1,
		EDGELINEWIDTH=0.3,
		edgestrokec="black",
		#edgelabel= g |> edges |> collect .|> weight,
		#edgelabelc="red",
		#edgelabeldistx=0, edgelabeldisty=0,
		#EDGELABELSIZE=5,
		#layout=(args...)->spring_layout(args...; C=2),
	)
end

# ╔═╡ 2521c391-dd5b-4aae-9a66-d1ea09639560
plot_search_tree(bfs_search)

# ╔═╡ 7451bf70-cee7-4f43-8d1b-3e83b5e1db62
plot_search_tree(dfs_search)

# ╔═╡ 88616ad4-6168-4b93-87d9-7548f280c022
plot_search_tree(prev)

# ╔═╡ 712b8861-d94f-4df6-8117-32e1c8fe1db3
md"**The distances table**"

# ╔═╡ 2ef9ce68-5546-4b32-93c5-e4c07ade8563
DataFrame("node"=>1:nv(wg), "dist"=>dist)
# DataFrame((1:nv(wg) .|> string) .=> dist)

# ╔═╡ 1d6e5312-9749-40d0-941f-d1b19f839141
md"""
> **Osservazione:** è possibile applicare l'algoritmo di Dijkstra anche su *grafi non pesati*. Basta pensare che un grafo non pesato può essere rappresentato come un grafo pesato con **pesi identici** (esempio, $w(e) = 1$ per ogni $e \in E$).
"""

# ╔═╡ fcbaa7b5-35b4-4e4a-8a48-3948f05c0cce
md"""
## Metodo semplice per la generazione di labirinti
Prima di porcedere abbiamo bisogno di definire un metodo per generare casualmente un labirinto.

Un primo approccio banale è quello di generare un grafo **griglia**, ed eseguire una visita DFS su di esso.
L'albero della visita risultante potrebbe essere un potenziale candidato labirinto.
"""

# ╔═╡ 941094ee-abf7-4e6c-8f87-d268ee634fd7
md"""
numero di righe = $(@bind rows Slider(1:20, show_value=true, default=10))\
numero di colonne = $(@bind cols Slider(1:20, show_value=true, default=10))
"""

# ╔═╡ bc1004e7-3bb2-4f31-8d30-4f65781d9c26
begin
	n = rows*cols
	x = ([1:cols...] .- (cols/2)) ./ (cols/2)
	y = ([1:rows...] .- (rows/2)) ./ (rows/2)

	coords = Iterators.product(x, y) |> collect
	x_coord = push!(Float64[], first.(coords)...)
	y_coord = push!(Float64[], last.(coords)...)
	maze_gird = Graphs.grid((cols, rows))
end

# ╔═╡ d8051e9e-f762-49ef-8972-bae3b1936b22
gplot(maze_gird, x_coord, y_coord)

# ╔═╡ 571246a3-73cb-47c8-90e3-a565d4510441
start, finish = 1, n

# ╔═╡ c3c933d2-80c3-4d55-94f4-f6c1305545fe
naive_maze = DFS(maze_gird, start)

# ╔═╡ c91ae1ca-6c1a-42c7-aab1-1dea4757d66a
gplot(naive_maze.search_tree, x_coord, y_coord, nodefillc="white", nodestrokec=colorant"black", nodestrokelw=1, edgestrokec="black", arrowlengthfrac=0)

# ╔═╡ a2b85e57-a858-47be-ad6e-db3566045626
md"""
Purtroppo si vede chiaramente che il nostro labirinto banale appena generato non sembra essere molto "random" 🙁

Questo perché i vicini di ogni nodo esplorato $u$ sono visitati "in ordine".
Perciò una prima idea potrebbe essere quella di *"mescolarli"* e visitarli in disordine.
"""

# ╔═╡ 52f8f449-4775-4b75-b437-d0125ae71a72
begin
	rand_maze = random_DFS(maze_gird, start)
	gplot(rand_maze.search_tree, x_coord, y_coord, nodefillc="white", nodestrokec=colorant"black", nodestrokelw=1, edgestrokec="black", arrowlengthfrac=0)
end

# ╔═╡ 6d3262b9-35cf-4dac-b58a-2443c52525f4
md"""
Molto meglio, ci siamo quasi...

Osserviamo che il labirinto è pur sempre un albero, perciò abbiamo un solo cammino dall'entrata all'uscita.

Se siamo abbastanza sfortunati, potrebbe capitarci un labirinto composto da un **singolo corridoio**, dall'entrata all'uscita (e ciò è legittimo, perché sarebbe comunque un albero)...

Perciò sarebbe una buona idea aggiungere un po' di *"archi random"*.
"""

# ╔═╡ 308a4144-6792-409f-828c-3e9679641c69
begin
	# add some random edges
	for _=1:(n/2.5)
		u = rand(1:n)
		v = rand(neighbors(maze_gird, u))
		add_edge!(rand_maze.search_tree, u, v)
	end
	maze = Graph(rand_maze.search_tree)
end

# ╔═╡ 573ce43b-2f49-4d44-9583-6fdd26edc630
gplot(maze, x_coord, y_coord, nodefillc="white", nodestrokec=colorant"black", nodestrokelw=1, edgestrokec="black", arrowlengthfrac=0)

# ╔═╡ 4697df2d-5c28-4a9e-b79c-3b3fcb054257
md"Et voilà, in nostro **labirinto random**! 🥳"

# ╔═╡ 79f5e786-6d1c-4b81-87ac-0ecec4a64b9e
md"""
## Risoluzione del labirinto
Di seguito le soluzioni del labirinto ottenute tramite l'esecuzione dei tre algoritmi.
"""

# ╔═╡ d280654a-de48-4051-a120-161de6823e2a
begin
	function plot_solution(g, solution)
		p₁ = gplot(
			g, x_coord, y_coord,
			nodefillc="white",
			nodestrokec=colorant"black",
			nodestrokelw=1,
			edgestrokec="black",
			arrowlengthfrac=0
		)
		
		p₂ = gplot(
			Graph(solution), x_coord, y_coord,
			NODESIZE=0,
			edgestrokec="red",
			EDGELINEWIDTH=10/√n
		)
		
		Compose.compose(p₁, p₂)
	end
end

# ╔═╡ bae766f2-4fda-46f0-8156-5bc3bae4515f
md"""
### Con visita BFS
"""

# ╔═╡ 9c1c2152-a8f7-44f0-a6cf-7144a9338557
begin
	bfs_solution = BFS(maze, start)
	bfs_solution_tree = bfs_solution.search_tree

	bfs_path = let
		current = first(bfs_solution_tree.badjlist[finish])
		path = [Edge(finish, current)]
		while current ≠ start
			previor = first(bfs_solution_tree.badjlist[current])
			push!(path, Edge(current, previor))
			current = previor
		end
		path
	end
end

# ╔═╡ b9ba3ae1-c8ee-4222-9164-797e3586069c
begin
	last_index₁ = findfirst(x->x==finish, bfs_solution.visit_order)

	md"""
	 time $(@bind t₄ Slider(1:last_index₁+1, show_value=true, default=true))
	"""
end

# ╔═╡ 4839aa4d-a51d-4c66-aec1-a2456ab824de
t₄ ≤ last_index₁ ? plot_search(bfs_solution, t₄, locs_x=x_coord, locs_y=y_coord) : plot_solution(rand_maze.search_tree, bfs_path)

# ╔═╡ 4ff62f2b-fb7a-4b44-9265-ba104e2aedb3
md"""
### Con visita DFS
"""

# ╔═╡ c96e988f-ea8b-466f-8ff3-620443e26f30
begin
	dfs_solution = DFS(maze, start)
	dfs_solution_tree = dfs_solution.search_tree

	dfs_path = let
		current = first(dfs_solution_tree.badjlist[finish])
		path = [Edge(finish, current)]
		while current ≠ start
			previor = first(dfs_solution_tree.badjlist[current])
			push!(path, Edge(current, previor))
			current = previor
		end
		path
	end
end

# ╔═╡ 33510dcf-1c91-4651-81dd-867b201418de
begin
	last_index₂ = findfirst(x->x==finish, dfs_solution.visit_order)

	md"""
	 time $(@bind t₅ Slider(1:last_index₂+1, show_value=true, default=true))
	"""
end

# ╔═╡ 49389be0-05ac-4c96-a9a6-266a4cca0eb8
t₅ ≤ last_index₂ ? plot_search(dfs_solution, t₅, locs_x=x_coord, locs_y=y_coord) : plot_solution(rand_maze.search_tree, dfs_path)

# ╔═╡ 9697b21e-7ca6-498f-bb24-6a7e073be40c
md"""
### Con algoritmo di Dijkstra
"""

# ╔═╡ 61dae2c4-7ed8-4fca-ba1d-aaf63b5f37ea
begin
	ĝ = SimpleWeightedGraph(maze)
	_, dijk_solution, dijk_search = Dijkstra(ĝ, start)
	
	dijk_path = let
		current = dijk_solution[finish]
		path = [Edge(finish, current)]
		while current ≠ start
			push!(path, Edge(current, dijk_solution[current]))
			current = dijk_solution[current]
		end
		path
	end
end

# ╔═╡ 594cff31-f1ee-44d9-bed0-feb6c0731913
begin
	last_index₃ = findfirst(x->x==finish, dijk_search.visit_order)
	if last_index₃ == nothing
		last_index₃ = length(dijk_search.visit_order)
	end

	md"""
	 time $(@bind t₆ Slider(1:last_index₃+1, show_value=true, default=true))
	"""
end

# ╔═╡ 4759f0b7-af2a-4a29-a38b-0279475351d1
t₆ ≤ last_index₃ ? plot_search(dijk_search, t₆, locs_x=x_coord, locs_y=y_coord, EDGELABELSIZE=0, edgestrokec=colorant"black") : plot_solution(rand_maze.search_tree, dijk_path)

# ╔═╡ 54bbfa45-3425-4ee3-b9a7-4ec5f38a9467
md"""
### Confronti
Di seguito una tabella che riporta le lughezze dei cammini trovati dai tre algoritmi.
Come ci aspettavamo, la visita BFS e l'algoritmo di Dijkstra generano sempre una **soluzione ottim**, mentre la visita DFS potrebbe generare una **soluzione peggiore** (se non è così nell'esempio, prova a generare un nuovo labirinto).
"""

# ╔═╡ 4cb7b542-a7bd-4450-a353-e014f41e44f2
DataFrame(
	Algo = [BFS, DFS, Dijkstra],
	Solution_legnth = length.([bfs_path, dfs_path, dijk_path])
)

# ╔═╡ e34bb748-4f14-4d95-a3dc-7f47e94cde2a
md"""
In ogni caso, la cosa più importante è che Arianna riesca a fuggire sana e salva dal labirinto per raggiungere il suo amato Teseo (non necessariamente con la strada più breve).

Perciò ci facciamo andare bene anche la visita in profondità. 🤓
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
Compose = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
DataStructures = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
SimpleWeightedGraphs = "47aef6b3-ad0c-573a-a1e2-d07658019622"

[compat]
Colors = "~0.12.8"
Compose = "~0.9.4"
DataFrames = "~1.3.4"
DataStructures = "~0.18.13"
GraphPlot = "~0.5.2"
Graphs = "~1.7.1"
Plots = "~1.31.2"
PlutoUI = "~0.7.39"
SimpleWeightedGraphs = "~1.2.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "ff38036fb7edc903de4e79f32067d8497508616b"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.2"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "1fd869cc3875b57347f7027521f561cf46d1fcd8"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.19.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "9be8be1d8a6f44b96482c8af52238ea7987da3e3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.45.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "d853e57661ba3a57abcdaa201f4c9917a93487a2"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.4"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "daa21eb85147f72e41f6352a57fccea377e310a9"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "ccd479984c7838684b3ac204b716c89955c76623"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "51d2dfe8e590fbd74e7a842cf6d13d8a2f45dc01"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.6+0"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "037a1ca47e8a5989cc07d19729567bb71bfabd0c"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.66.0"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "c8ab731c9127cd931c93221f65d6a1008dad7256"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.66.0+0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "83ea630384a13fc4f002b77690bc0afeb4255ac9"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.2"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.GraphPlot]]
deps = ["ArnoldiMethod", "ColorTypes", "Colors", "Compose", "DelimitedFiles", "Graphs", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "5cd479730a0cb01f880eff119e9803c13f214cab"
uuid = "a2cc645c-3eea-5389-862e-a155d0052231"
version = "0.5.2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "db5c7e27c0d46fd824d470a3c32a4fc6c935fa96"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "9fad98d1f1c40c50d4b200176e8f00103d7ec826"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.1.0"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "46a39b9c58749eefb5f2dc1178cb8fab5332b1ab"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.15"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "5d4d2d9904227b8bd66386c1138cf4d5ffa826bf"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.9"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "891d3b4e8f8415f53108b4918d0183e61e18015b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e60321e3f2616584ff98f0a4f18d98ae6f89bbb3"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.17+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "8162b2f8547bc23876edd0c5181b27702ae58dce"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.0.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "9888e59493658e476d3073f1ce24348bdc086660"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "b29873144e57f9fcf8d41d107138a4378e035298"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.31.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "c6c0f690d0cc7caddb74cef7aa847b824a16b256"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "2690681814016887462cf5ac37102b51cd9ec781"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.2"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "22c5201127d7b243b9ee1de3b43c408879dff60f"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.3.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays", "Test"]
git-tree-sha1 = "a6f404cc44d3d3b28c793ec0eb59af709d827e4e"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.2.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "e972716025466461a3dc1588d9168334b71aafff"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.1"

[[deps.StaticArraysCore]]
git-tree-sha1 = "66fe9eb253f910fe8cf161953880cfdaef01cdf0"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.0.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2c11d7290036fe7aac9038ff312d3b3a2a5bf89e"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.4.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "472d044a1c8df2b062b23f222573ad6837a615ba"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.19"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "ec47fb6069c57f1cee2f67541bf8f23415146de7"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.11"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "e59ecc5a41b000fa94423a578d29290c7266fc10"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "58443b63fb7e465a8a7210828c91c08b92132dff"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.14+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╠═656ea700-045a-11ed-095e-41d8aa67b9af
# ╟─671e7283-7ff4-497a-afcc-ca1eb1d43591
# ╟─7c8c95be-4e4b-4bf3-b541-7e73abf02bd2
# ╟─dad001a0-ff58-4a62-8e2a-97ecfd8a491d
# ╟─4b01c4be-ce31-4bf8-88b5-ce46070d986f
# ╟─e5bb9db5-2708-449a-a0ca-06daf96dba1d
# ╟─2ce9ffd9-594a-4325-b293-89caea578263
# ╟─4d3147fd-09fc-4a18-b7ae-3ca3a622013e
# ╠═888f8c53-08dd-489c-9902-36874ad8d96b
# ╠═9457c3fc-7e83-486f-84b6-30a42697b6f1
# ╟─9d0fd8e0-85b0-41ac-baaa-fa2bf0c9265d
# ╟─67c43de2-9314-4538-9a4c-a04d7af4fe83
# ╟─6f568adb-8348-4fe5-8111-8704305a5782
# ╠═580c8d80-b941-4697-8331-448f858374a4
# ╟─9ca87661-e5b9-4cd1-beb1-e7eb2a41d5ea
# ╟─30950c0f-fb6e-48ca-b533-906499be505f
# ╟─2521c391-dd5b-4aae-9a66-d1ea09639560
# ╟─acc19bba-dc4f-47b8-b920-b3b8bb847aa7
# ╟─175b272f-601e-4b67-a8d7-cfaf115b88b2
# ╟─02292df4-40c6-44c3-8515-3cb7d18b0283
# ╟─9c3e4a77-9fa3-4f55-9486-0a1bf05249e3
# ╠═73077b44-6d0b-4641-a3ef-bf7d00a5dcfe
# ╠═d74053b1-b5d8-4eed-8832-b722b35e1926
# ╟─434091e0-3db7-4cd6-ac13-6f6f5a803ac1
# ╟─86f19fb9-125a-443d-aa8c-fcee8b3ba951
# ╟─7451bf70-cee7-4f43-8d1b-3e83b5e1db62
# ╟─cfb9c99a-2ca2-4b3e-96d7-e203c92baf2b
# ╟─8ac046aa-f817-499c-8688-cc734b472c78
# ╟─eb87622b-87e1-4366-95d1-d29fb4540224
# ╟─b47c9ec0-8d85-4b6b-87c9-54a06ebc22c3
# ╟─254643d0-5e86-4722-96e5-5bc7940d8ac8
# ╠═e4fefa2f-404f-4034-9744-b1ce8592f52e
# ╟─5705e51c-1752-4acd-8a11-6e7afaed0867
# ╠═8d042281-61b2-4cf2-8f0f-4f42f0fb4050
# ╠═826b1e26-36b8-4ba9-a535-b49600536526
# ╟─b52b3a7b-a953-4d9f-9b00-6fd28714d20c
# ╟─79d11ee0-24f7-44ac-aae8-655255e76dcf
# ╟─86210bf9-b85d-419a-ac4f-3cc8a7babc3f
# ╟─88616ad4-6168-4b93-87d9-7548f280c022
# ╟─712b8861-d94f-4df6-8117-32e1c8fe1db3
# ╟─2ef9ce68-5546-4b32-93c5-e4c07ade8563
# ╟─1d6e5312-9749-40d0-941f-d1b19f839141
# ╟─fcbaa7b5-35b4-4e4a-8a48-3948f05c0cce
# ╟─941094ee-abf7-4e6c-8f87-d268ee634fd7
# ╟─bc1004e7-3bb2-4f31-8d30-4f65781d9c26
# ╟─d8051e9e-f762-49ef-8972-bae3b1936b22
# ╠═571246a3-73cb-47c8-90e3-a565d4510441
# ╠═c3c933d2-80c3-4d55-94f4-f6c1305545fe
# ╟─c91ae1ca-6c1a-42c7-aab1-1dea4757d66a
# ╟─a2b85e57-a858-47be-ad6e-db3566045626
# ╠═26101d0d-05c8-46db-9371-a68ec9a7382d
# ╟─52f8f449-4775-4b75-b437-d0125ae71a72
# ╟─6d3262b9-35cf-4dac-b58a-2443c52525f4
# ╠═308a4144-6792-409f-828c-3e9679641c69
# ╟─573ce43b-2f49-4d44-9583-6fdd26edc630
# ╟─4697df2d-5c28-4a9e-b79c-3b3fcb054257
# ╟─79f5e786-6d1c-4b81-87ac-0ecec4a64b9e
# ╟─d280654a-de48-4051-a120-161de6823e2a
# ╟─bae766f2-4fda-46f0-8156-5bc3bae4515f
# ╟─9c1c2152-a8f7-44f0-a6cf-7144a9338557
# ╟─b9ba3ae1-c8ee-4222-9164-797e3586069c
# ╟─4839aa4d-a51d-4c66-aec1-a2456ab824de
# ╟─4ff62f2b-fb7a-4b44-9265-ba104e2aedb3
# ╟─c96e988f-ea8b-466f-8ff3-620443e26f30
# ╟─33510dcf-1c91-4651-81dd-867b201418de
# ╟─49389be0-05ac-4c96-a9a6-266a4cca0eb8
# ╟─9697b21e-7ca6-498f-bb24-6a7e073be40c
# ╟─61dae2c4-7ed8-4fca-ba1d-aaf63b5f37ea
# ╟─594cff31-f1ee-44d9-bed0-feb6c0731913
# ╟─4759f0b7-af2a-4a29-a38b-0279475351d1
# ╟─54bbfa45-3425-4ee3-b9a7-4ec5f38a9467
# ╟─4cb7b542-a7bd-4450-a353-e014f41e44f2
# ╟─e34bb748-4f14-4d95-a3dc-7f47e94cde2a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
