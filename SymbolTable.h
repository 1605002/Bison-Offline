#include<bits/stdc++.h>
using namespace std;
typedef pair<string, string> pss;
typedef vector<string> vs;
typedef vector<pss> vpss;

const int B = 199;

class SymbolInfo
{
public:
    string name, typ;
    string returnType;
    string IDType;
    vs prms;
    bool isDefined = false;
    
    SymbolInfo* nxt;

    SymbolInfo(): nxt(0) {}
    SymbolInfo(string name, string typ): name(name), typ(typ), nxt(0) {}
    SymbolInfo(string name, string typ, string returnType, string IDType)
    : name(name), typ(typ), returnType(returnType), IDType(IDType), nxt(0){}
    SymbolInfo(string name, string typ, string returnType, string IDType, vs prms)
    : name(name), typ(typ), returnType(returnType), IDType(IDType), prms(prms), nxt(0){}
    SymbolInfo(string name, string typ, string returnType, string IDType, vs prms, bool isDefined)
    : name(name), typ(typ), returnType(returnType), IDType(IDType), prms(prms), nxt(0), isDefined(isDefined) {}

    string getName() { return name; }
    void setName(string name) { this->name = name; }
    string getTyp() { return typ; }
    void setTyp(string typ) { this->typ = typ; }
    SymbolInfo* getNxt() { return nxt; }
    void setNxt(SymbolInfo* nxt) { this->nxt = nxt; }
    bool operator==(const SymbolInfo& rhs) const { return name == rhs.name; }
    friend ostream& operator<<(ostream&, const SymbolInfo&);
    void fprint(FILE *fp)
    {
        fprintf(fp, "<%s, %s>", name.c_str(), typ.c_str());
    }

};

class ScopeTable
{
private:
    int n;
    ScopeTable* parentScope;
    int id;
    SymbolInfo** table;

    int getHash(string key, int n)
    {
        int h = 0;
        for(char c: key) h = (h*B+c)%n;

        return h;
    }

public:
    ScopeTable(int n, ScopeTable* parentScope, int id): n(n), parentScope(parentScope), id(id)
    {
        table = new SymbolInfo*[n];
        for(int i = 0; i < n; i++) table[i] = 0;
    }

    ScopeTable* getParentScope() { return parentScope; }
    void setParentScope(ScopeTable* parentScope) { this->parentScope = parentScope; }

    bool insertNode(string name, string typ, string returnType = "", string IDType = "", vs prms = vs(), bool isDefined = false)
    {
        int h = getHash(name, n);

        SymbolInfo *cur = table[h], *prev = 0;
        int cnt = 0;

        while(cur)
        {
            if(cur->getName() == name)
            {
                //cout<<SymbolInfo(name, typ)<<" already exists in current ScopeTable"<<endl<<endl;
                return false;
            }

            prev = cur;
            cur = cur->getNxt();
            cnt++;
        }

        cur = new SymbolInfo(name, typ);
        cur->returnType = returnType;
        cur->IDType = IDType;
        cur->prms = prms;
        cur->isDefined = isDefined;

        if(prev) prev->setNxt(cur);
        else table[h] = cur;

        //cout<<"Inserted in ScopeTable#" <<id<<" at position "<<h<<", "<<cnt<<endl<<endl;
        return true;
    }

    SymbolInfo* lookup(string name)
    {
        int h = getHash(name, n);

        SymbolInfo *cur = table[h];
        int cnt = 0;

        while(cur)
        {
            if(cur->getName() == name)
            {
                //cout<<"Found in ScopeTable#" <<id<<" at position "<<h<<", "<<cnt<<endl<<endl;
                break;
            }

            cur = cur->getNxt();
            cnt++;
        }

        return cur;
    }

    bool deleteNode(string name)
    {
        int h = getHash(name, n);

        SymbolInfo *cur = table[h], *prev = 0;
        int cnt = 0;

        while(cur)
        {
            if(cur->getName() == name)
            {
                if(prev) prev->setNxt(cur->getNxt());
                else table[h] = cur->getNxt();

                delete cur;

                //cout<<"Found in ScopeTable#" <<id<<" at position "<<h<<", "<<cnt<<endl;
                //cout<<"Deleted entry at "<<h<<", "<<cnt<<" from current ScopeTable"<<endl<<endl;

                return true;
            }

            prev = cur;
            cur = cur->getNxt();
            cnt++;
        }

        //cout<<"Not found in current scopeTable"<<endl<<endl;
        return false;
    }

    void fprint(FILE *fp)
    {
        fprintf(fp, "ScopeTable # %d\n", id);

        for(int i = 0; i < n; i++)
        {
            SymbolInfo *cur = table[i];
            if(!cur) continue;

            fprintf(fp, "%d -->", i);

            while(cur)
            {
                fprintf(fp, " ");
                cur->fprint(fp);
                cur = cur->getNxt();
            }
            fprintf(fp, "\n");
        }

	fprintf(fp, "\n");
    }

    void clearNode(SymbolInfo *cur)
    {
        if(cur == 0) return;

        if(cur->getNxt()) clearNode(cur->getNxt());
        delete cur;
    }

    ~ScopeTable()
    {
        for(int i = 0; i < n; i++) clearNode(table[i]);
        delete table;
    }

};

class SymbolTable
{
public:
    ScopeTable *curScope;
    int n;
    int curID;

    SymbolTable(int n): n(n), curID(1) { curScope = new ScopeTable(n, 0, 1); }

    void enterNew(FILE *fp)
    {
        ScopeTable *nw = new ScopeTable(n, curScope, ++curID);
        fprintf(fp, "New ScopeTable with id %d created\n\n", curID);
        //cout<<"New ScopeTable with id "<<curID<<" created"<<endl<<endl;
        curScope = nw;
    }

    void exitPrev(FILE *fp)
    {
        if(curScope->getParentScope() == 0) return;

        ScopeTable* togo = curScope->getParentScope();
        delete curScope;
        curScope = togo;
        curID--;

        fprintf(fp, "ScopeTable with id %d removed\n\n", curID+1);
        //cout<<"ScopeTable with id "<<curID+1<<" removed"<<endl<<endl;
    }

    bool insertNode(string name, string typ, string returnType = "", string IDType = "", vs prms = vs(), bool isDefined = false)
    {
         return curScope->insertNode(name, typ, returnType, IDType, prms, isDefined);
    }

    void removeNode(string name) { curScope->deleteNode(name); }

    SymbolInfo* lookup(string name)
    {
        ScopeTable *cur = curScope;

        while(cur)
        {
            SymbolInfo *r = cur->lookup(name);
            if(r) return r;

            cur = cur->getParentScope();
        }

        //cout<<"Not found"<<endl<<endl;
        return 0;
    }

    void fprint(FILE *fp)
    {
        ScopeTable *cur = curScope;
        while(cur)
        {
            cur->fprint(fp);
            cur = cur->getParentScope();
        }
    }

    void deleteScope(ScopeTable *cur)
    {
        if(cur->getParentScope()) deleteScope(cur->getParentScope());
        delete cur;
    }

    ~SymbolTable() { deleteScope(curScope); }
};

/*int main()
{
    int n;
    scanf("%d", &n);

    SymbolTable st(n);

    string t;
    while(cin>>t)
    {
        cout<<t;

        if(t == "I")
        {
            string name, typ;
            cin>>name>>typ;
            cout<<" "<<name<<" "<<typ<<endl<<endl;

            st.insertNode(name, typ);
        }
        else if(t == "L")
        {
            string name;
            cin>>name;
            cout<<" "<<name<<endl<<endl;

            st.lookup(name);
        }
        else if(t == "D")
        {
            string name;
            cin>>name;
            cout<<" "<<name<<endl<<endl;

            st.removeNode(name);
        }
        else if(t == "P")
        {
            string tp;
            cin>>tp;
            cout<<" "<<tp<<endl<<endl;

            if(tp == "A") st.printAll();
            else st.printCur();
        }
        else if(t == "S")
        {
            cout<<endl<<endl;
            st.enterNew();
        }
        else if(t == "E")
        {
            cout<<endl<<endl;
            st.exitPrev();
        }
    }

    return 0;
}*/
