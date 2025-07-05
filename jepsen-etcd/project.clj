(defproject jepsen-etcd "0.1.0-SNAPSHOT"
  :description "Jepsen etcd test"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url "https://www.eclipse.org/legal/epl-2.0/"}
  :main jepsen-etcd.core
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [jepsen "0.3.9"]
                 [verschlimmbesserung "0.1.3"]]
  :repl-options {:init-ns jepsen-etcd.core})
