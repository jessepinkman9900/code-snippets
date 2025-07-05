(ns jepsen-etcd.core
  (:require [clojure.tools.logging :refer :all]
            [clojure.string :as str]
            [jepsen [cli :as cli]
             [tests :as tests]
             [control :as c]
             [db :as db]]
            [jepsen.control.util :as cu]
            [jepsen.os.debian :as debian]))

(def dir "/opt/etcd")
(def binary "etcd")
(def logfile (str dir "/etcd.log"))
(def pidfile (str dir "/etcd.pid"))

(defn node-url
  "An http url for connecting to a node on a particular port"
  [node port]
  (str "http://" node ":" port))

(defn peer-url
  "The http url for other peers to talk to a node"
  [node]
  (node-url node 2380))

(defn client-url
  "The http url clients use to talk to a node"
  [node]
  (node-url node 2379))

(defn initial-cluster
  "Constructs an initial cluster string for a test like foo=foo:2380,bar=bar:2380,..."
  [test]
  (->> (:nodes test)
       (map (fn [node]
              (str node "=" (peer-url node))))
       (str/join ",")))

(defn db
  "Etcd DB for a particular version"
  [version]
  (reify db/DB
    (setup! [_ test node]
      (info "installing etcd" version)
      (c/su
       (let [url (str "https://github.com/etcd-io/etcd/releases/download/" version "/etcd-" version "-linux-amd64.tar.gz")]
         (cu/install-archive! url dir))

       (cu/start-daemon!
        {:logfile logfile
         :pidfile pidfile
         :chdir dir}
        binary
        :--log-outputs  :stderr
        :--name (name node)
        :--listen-peer-urls (peer-url node)
        :--listen-client-urls (client-url node)
        :--advertise-client-urls (client-url node)
        :--initial-cluster-state :new
        :--initial-advertise-peer-urls (peer-url node)
        :--initial-cluster (initial-cluster test))

       (Thread/sleep 10000)))

    (teardown! [_ test node]
      (info "tearing down etcd" version)
      (cu/stop-daemon! binary pidfile)
      (c/su (c/exec :rm :-rf dir)))
    
    db/LogFiles
    (log-files [_ test node]
      [logfile])))

(defn etcd-test
  "Runs an etcd test"
  [opts]
  (merge tests/noop-test
         opts
         {:name "etcd"
          :os debian/os
          :db (db "v3.5.1")
          :pure-generators true}))

(defn -main
  "Handle CLI args"
  [& args]
  (cli/run! (merge (cli/single-test-cmd {:test-fn etcd-test})
                   (cli/serve-cmd))
            args))

