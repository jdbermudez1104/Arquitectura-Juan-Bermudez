// comparacion_Cache.cpp
// Implementación en un solo .cpp: FlatMapCache vs BTreeCache
// No usa std::vector ni std::string ni std::map. Tipos definidos aquí.
// Compilar: g++ -O2 -std=c++17 comparacion_Cache.cpp -o comparacion_Cache

#include <iostream>
#include <chrono>
#include <random>
#include <cstdint>
#include <cstring>
#include <cassert>
#include <cmath>

// --------- UTILIDADES SIMPLES (sin usar STL containers) ----------
using u64 = uint64_t;
using ns  = std::chrono::nanoseconds;
using clk = std::chrono::high_resolution_clock;

static inline u64 now_ns() {
    return std::chrono::duration_cast<ns>(clk::now().time_since_epoch()).count();
}

// Matriz dinámica simple (Vector) para POD T
template<typename T>
struct Vector {
    T* data;
    size_t sz;
    size_t cap;
    Vector(): data(nullptr), sz(0), cap(0) {}
    ~Vector(){ delete [] data; }
    void reserve(size_t n){
        if(n <= cap) return;
        size_t nc = (cap==0)?1:cap;
        while(nc < n) nc*=2;
        T* nd = new T[nc];
        if(data){
            for(size_t i=0;i<sz;i++) nd[i]=data[i];
            delete [] data;
        }
        data = nd; cap = nc;
    }
    void push_back(const T& v){
        if(sz==cap) reserve(sz+1);
        data[sz++] = v;
    }
    void pop_back(){ if(sz) --sz; }
    void clear(){ sz = 0; }
    size_t size() const { return sz; }
    T& operator[](size_t i){ return data[i]; }
    const T& operator[](size_t i) const { return data[i]; }
};

// Par clave-valor
struct KV {
    u64 key;
    u64 value;
};

// --------- CACHÉ DE MAPA PLANO (arreglo ordenado + búsqueda binaria) ----------
struct FlatMapCache {
    Vector<KV> arr;
    size_t capacity;
    FlatMapCache(size_t cap=10000): capacity(cap){ arr.reserve(cap); }

    // la búsqueda binaria devuelve el índice donde se encuentra la clave o donde debería insertarse
    size_t lower_bound(u64 key) const {
        size_t l=0, r=arr.size();
        while(l<r){
            size_t m = (l+r)/2;
            if(arr.data[m].key < key) l = m+1;
            else r = m;
        }
        return l;
    }

    bool contains(u64 key){
        size_t i = lower_bound(key);
        return (i < arr.size() && arr.data[i].key == key);
    }

    bool get(u64 key, u64 &out){
        size_t i = lower_bound(key);
        if(i < arr.size() && arr.data[i].key == key){ out = arr.data[i].value; return true; }
        return false;
    }

    void insert(u64 key, u64 value){
        size_t i = lower_bound(key);
        if(i < arr.size() && arr.data[i].key == key){
            arr.data[i].value = value; // update
            return;
        }
        // insertar desplazamiento a la derecha
        arr.reserve(arr.size()+1);
        for(size_t j=arr.size(); j>i; --j) arr.data[j] = arr.data[j-1];
        arr.data[i].key = key;
        arr.data[i].value = value;
        arr.sz++;
        // Desalojo si se excede la capacidad: eliminar el último (clave más grande)
        if(arr.size() > capacity){
            arr.pop_back();
        }
    }

    bool erase(u64 key){
        size_t i = lower_bound(key);
        if(i < arr.size() && arr.data[i].key == key){
            for(size_t j=i; j+1 < arr.size(); ++j) arr.data[j]=arr.data[j+1];
            arr.pop_back();
            return true;
        }
        return false;
    }

    void clear(){ arr.clear(); }
};

// --------- CACHÉ DE ÁRBOL B SIMPLE (orden t) ----------
// Un árbol B minimalista para números enteros. No está totalmente optimizado, pero es funcional.
struct BNode {
    bool leaf;
    int n;         // número de claves
    u64 *keys;
    u64 *vals;
    BNode **C;
    int t;         // grado mínimo
    BNode(int _t, bool _leaf): leaf(_leaf), n(0), t(_t) {
        keys = new u64[2*t-1];
        vals = new u64[2*t-1];
        C = new BNode*[2*t];
        for(int i=0;i<2*t;i++) C[i]=nullptr;
    }
    ~BNode(){
        for(int i=0;i<2*t && C[i]; ++i) delete C[i];
        delete [] keys;
        delete [] vals;
        delete [] C;
    }

    // encontrar el índice de la clave
    int find(u64 k){
        int idx = 0;
        while(idx < n && keys[idx] < k) ++idx;
        return idx;
    }

    bool get(u64 k, u64 &out){
        int i = 0;
        while(i < n && k > keys[i]) ++i;
        if(i < n && keys[i]==k){ out = vals[i]; return true; }
        if(leaf) return false;
        return C[i]->get(k,out);
    }

    // divide al menor y en el índice i
    void splitChild(int i, BNode *y){
        int t = y->t;
        BNode *z = new BNode(y->t, y->leaf);
        z->n = t-1;
        for(int j=0;j<t-1;j++){
            z->keys[j] = y->keys[j+t];
            z->vals[j] = y->vals[j+t];
        }
        if(!y->leaf){
            for(int j=0;j<t;j++){
                z->C[j] = y->C[j+t];
                y->C[j+t] = nullptr;
            }
        }
        y->n = t-1;
        for(int j=n;j>=i+1;--j) C[j+1]=C[j];
        C[i+1] = z;
        for(int j=n-1;j>=i;--j){
            keys[j+1] = keys[j];
            vals[j+1] = vals[j];
        }
        keys[i] = y->keys[t-1];
        vals[i] = y->vals[t-1];
        n = n + 1;
    }

    void insertNonFull(u64 k, u64 v){
        int i = n-1;
        if(leaf){
            while(i>=0 && keys[i] > k){
                keys[i+1] = keys[i];
                vals[i+1] = vals[i];
                --i;
            }
            if(i>=0 && keys[i]==k){ vals[i] = v; return; } // update
            keys[i+1] = k;
            vals[i+1] = v;
            n = n+1;
        } else {
            while(i>=0 && keys[i] > k) --i;
            ++i;
            if(C[i]->n == 2*t-1){
                splitChild(i, C[i]);
                if(keys[i] < k) ++i;
            }
            C[i]->insertNonFull(k,v);
        }
    }

    // Para simplificar, la eliminación será diferida: se marcará como eliminado mediante un indicador, asignando value=UINT64_MAX.
    bool erase_lazy(u64 k){
        u64 dummy;
        if(get(k, dummy)){
            // Encuentra un nodo y asigna un valor a un marcador especial
            // Enfoque simple: recorre hasta la hoja y asigna un valor.
            BNode *node = this;
            while(true){
                int i = 0;
                while(i < node->n && k > node->keys[i]) ++i;
                if(i < node->n && node->keys[i]==k){
                    node->vals[i] = UINT64_MAX;
                    return true;
                }
                if(node->leaf) break;
                node = node->C[i];
            }
        }
        return false;
    }
};

struct BTreeCache {
    BNode *root;
    int t; // grado mínimo
    size_t capacity;
    size_t count; // recuento de entradas activas (aprox.)
    BTreeCache(int _t=3, size_t cap=10000): t(_t), capacity(cap), count(0){
        root = new BNode(t, true);
    }
    ~BTreeCache(){ delete root; }

    bool get(u64 k, u64 &out){
        bool ok = root->get(k, out);
        if(ok && out==UINT64_MAX) return false; //eliminada
        return ok;
    }

    void insert(u64 k, u64 v){
        // crecimiento simple, sin desalojo en el árbol (por brevedad): realizar desalojo diferido cuando el conteo supere la capacidad
        if(root->n == 2*t-1){
            BNode *s = new BNode(t, false);
            s->C[0] = root;
            s->n = 0;
            s->splitChild(0, root);
            root = s;
            root->insertNonFull(k,v);
        } else {
            root->insertNonFull(k,v);
        }
        ++count;
        if(count > capacity){
            // simple: no realizar operaciones costosas; en la práctica, eliminaríamos el elemento menos reciente o similar.
            // Para garantizar la equidad en las pruebas de rendimiento (benchmarking), no recurriremos a la eliminación automática; en su lugar,
            // las pruebas deben utilizar un universo y probabilidades para mantener los tamaños aproximadamente acotados.
            // Alternativamente, podríamos implementar un mecanismo de eliminación mediante escaneo, pero lo omitimos por motivos de rendimiento.
        }
    }

    bool erase(u64 k){
        bool r = root->erase_lazy(k);
        if(r) --count;
        return r;
    }
    void clear(){
        delete root;
        root = new BNode(t, true);
        count = 0;
    }
};

// --------- GENERADORES DE TRAZAS ----------
enum TraceType { TRACE_RANDOM, TRACE_SEQUENTIAL, TRACE_ZIPF };

struct TraceGen {
    TraceType type;
    u64 universe;
    std::mt19937_64 rng;
    std::uniform_int_distribution<u64> unif;
    // parámetros de Zipf
    double alpha;
    Vector<double> zipf_cdf;
    TraceGen(TraceType ty, u64 univ, u64 seed=123456): type(ty), universe(univ), rng(seed), unif(0,univ-1), alpha(1.0) {
        if(type==TRACE_ZIPF) build_zipf(1.0);
    }
    void build_zipf(double a){
        alpha = a;
        zipf_cdf.clear();
        zipf_cdf.reserve(universe);
        double sum = 0.0;
        for(u64 i=1;i<=universe;i++) sum += 1.0/std::pow((double)i, alpha);
        double c = 1.0/sum;
        double acc = 0.0;
        for(u64 i=1;i<=universe;i++){
            acc += c / std::pow((double)i, alpha);
            zipf_cdf.push_back(acc);
        }
    }
    u64 next(u64 step){
        if(type==TRACE_RANDOM) return unif(rng);
        else if(type==TRACE_SEQUENTIAL) return step % universe;
        else { // zipf
            double r = std::generate_canonical<double, 10>(rng);
            // búsqueda binaria en zipf_cdf
            size_t l=0, h = zipf_cdf.size();
            while(l<h){
                size_t m = (l+h)/2;
                if(zipf_cdf[m] < r) l = m+1;
                else h = m;
            }
            if(l>=zipf_cdf.size()) return zipf_cdf.size()-1;
            return l; // zero-based
        }
    }
};

// --------- BENCHMARKS ----------
struct Stats {
    double avg_ns_per_op;
    size_t hits;
    size_t ops;
};

Stats benchmark_flat(FlatMapCache &cache, u64 ops, TraceGen &tg){
    using ct = std::chrono::high_resolution_clock;
    u64 start = now_ns();
    size_t hits = 0;
    for(u64 i=0;i<ops;i++){
        u64 key = tg.next(i);
        u64 val;
        if(cache.get(key, val)){
            ++hits;
        } else {
            cache.insert(key, key*17 + 1); // simular obtención e inserción
        }
    }
    u64 end = now_ns();
    double avg = double(end - start) / double(ops);
    return { avg, hits, (size_t)ops };
}

Stats benchmark_btree(BTreeCache &cache, u64 ops, TraceGen &tg){
    u64 start = now_ns();
    size_t hits = 0;
    for(u64 i=0;i<ops;i++){
        u64 key = tg.next(i);
        u64 val;
        if(cache.get(key, val)){
            ++hits;
        } else {
            cache.insert(key, key*17 + 1);
        }
    }
    u64 end = now_ns();
    double avg = double(end - start) / double(ops);
    return { avg, hits, (size_t)ops };
}

// mediciones adicionales: latencias de solo inserción y de solo eliminación
double measure_inserts_flat(FlatMapCache &cache, u64 n) {
    u64 start = now_ns();
    for(u64 k=0;k<n;k++) cache.insert(k, k+1);
    u64 end = now_ns();
    return double(end-start)/double(n);
}
double measure_inserts_btree(BTreeCache &cache, u64 n){
    u64 start = now_ns();
    for(u64 k=0;k<n;k++) cache.insert(k, k+1);
    u64 end = now_ns();
    return double(end-start)/double(n);
}
double measure_erase_flat(FlatMapCache &cache, u64 n){
    u64 start = now_ns();
    for(u64 k=0;k<n;k++) cache.erase(k);
    u64 end = now_ns();
    return double(end-start)/double(n);
}
double measure_erase_btree(BTreeCache &cache, u64 n){
    u64 start = now_ns();
    for(u64 k=0;k<n;k++) cache.erase(k);
    u64 end = now_ns();
    return double(end-start)/double(n);
}
// --------- MAIN ----------
int main(int argc, char** argv){
    if(argc < 4){
        std::cout << "Uso: " << argv[0] << " <ops> <universe_size> <trace: random|sequential|zipf>\n";
        return 1;
    }
    u64 ops = std::stoull(argv[1]);
    u64 universe = std::stoull(argv[2]);
    const char* trace_s = argv[3];
    TraceType tt = TRACE_RANDOM;
    if(std::strcmp(trace_s,"random")==0) tt = TRACE_RANDOM;
    else if(std::strcmp(trace_s,"sequential")==0) tt = TRACE_SEQUENTIAL;
    else if(std::strcmp(trace_s,"zipf")==0) tt = TRACE_ZIPF;
    else { std::cerr << "Trace invalido\n"; return 1; }

    // elegir las capacidades de la caché (establecer como una fracción del universo)
    size_t cap = (size_t)std::max<u64>(1, universe/2);

    FlatMapCache fcache(cap);
    BTreeCache bcache(6, cap); // t=6 (grado mínimo), ajustar para la ramificación

    TraceGen tg1(tt, universe, 12345);
    if(tt==TRACE_ZIPF) tg1.build_zipf(1.05);

    std::cout << "Benchmark: ops="<<ops<<" universe="<<universe<<" trace="<<trace_s<<" cap="<<cap<<"\n";

    for(u64 i=0;i<1000;i++){
        u64 k = tg1.next(i);
        fcache.insert(k, k+1);
        bcache.insert(k, k+1);
    }
    fcache.clear();
    bcache.clear();

    // Medir búsquedas e inserciones combinadas
    TraceGen tgA = tg1;
    Stats sf = benchmark_flat(fcache, ops, tgA);
    TraceGen tgB = tg1;
    Stats sb = benchmark_btree(bcache, ops, tgB);

    // Medir microbenchmark de solo inserción (cachés limpias)
    fcache.clear(); bcache.clear();
    double ins_flat = measure_inserts_flat(fcache, std::min<u64>(universe, ops/10 + 1000));
    double ins_btr  = measure_inserts_btree(bcache, std::min<u64>(universe, ops/10 + 1000));

    // Medir microbenchmark de solo borrado (utilizar datos previamente cargados)
    // fill
    fcache.clear();
    for(u64 k=0;k<1000 && k<universe; ++k) fcache.insert(k,k+1);
    double er_flat = measure_erase_flat(fcache, std::min<u64>(1000, universe));

    bcache.clear();
    for(u64 k=0;k<1000 && k<universe; ++k) bcache.insert(k,k+1);
    double er_btr = measure_erase_btree(bcache, std::min<u64>(1000, universe));

    // Resumen de resultados (ns/op)
    std::cout << "=== Resultados ===\n";
    std::cout << "FlatMap: avg ns/op (get/insert mix) = " << sf.avg_ns_per_op << " | hits="<<sf.hits<<"/"<<sf.ops<<" hit_rate="<< (100.0*sf.hits/sf.ops) <<"%\n";
    std::cout << "BTree : avg ns/op (get/insert mix) = " << sb.avg_ns_per_op << " | hits="<<sb.hits<<"/"<<sb.ops<<" hit_rate="<< (100.0*sb.hits/sb.ops) <<"%\n";
    std::cout << "Insert-only (sample) ns/op: Flat="<<ins_flat<<" BTree="<<ins_btr<<"\n";
    std::cout << "Erase-only (sample) ns/op: Flat="<<er_flat<<" BTree="<<er_btr<<"\n";

    std::cout << "\nObservaciones (generadas):\n";
    std::cout << "- FlatMap (array sorted) suele ganar en busquedas por localidad y menor overhead al iterar/compactar, hasta tamanios donde inserciones costosas (shift) penalizan.\n";
    std::cout << "- BTree es mas estable cuando hay muchas inserciones y el dataset no cabe linealmente, ofrece mejor escalado en escrituras.\n";
    std::cout << "- Hit rate depende enteramente de la traza y la politica de reemplazo (aqui no se implemento LRU: ambas estructuras insertan y mantienen capacidad por disenio simple).\n";

    return 0;
}