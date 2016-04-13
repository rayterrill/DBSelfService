<?php

namespace App\Controller;

use App\Controller\AppController;
use Cake\Datasource\ConnectionManager; /* needed to get raw SQL access to the database */

class DbsController extends AppController
{
    public function initialize()
    {
        parent::initialize();
        
        $this->loadComponent('Flash'); // Include the FlashComponent
    }

    public function index()
    {
        $this->set('dbs', $this->Dbs->find('all', ['conditions' => ['Dbs.owner =' => strtolower($_SERVER['AUTH_USER'])]]));
    }

    public function view($id)
    {
        $db = $this->Dbs->get($id);
        $this->set(compact('db'));
    }
    
    private function logDBCreateOrDelete($operation, $databaseName, $username) {
       $conn = ConnectionManager::get('default');
       $conn->execute("insert into dbo.dbfifoqueue (operation, databaseName, insertDate, username) values (?, ?, GETDATE(), ?)", array($operation, $databaseName, $username));       
    }
    
    private function logUsage($operation, $databaseName, $username) {
       $conn = ConnectionManager::get('default');
       $conn->execute("insert into dbo.usage (operation, database_name, actionDate, username) values (?, ?, GETDATE(), ?)", array($operation, $databaseName, $username));
    }

    public function add()
    {
        $db = $this->Dbs->newEntity();
        if ($this->request->is('post')) {
            $db = $this->Dbs->patchEntity($db, $this->request->data);
            if ($this->Dbs->save($db)) {
                //log this into the fifo queue table to be processed
                $this->logDBCreateOrDelete('CREATE', $this->request->data['database_name'], $this->request->data['owner']);
                //log this action into our usage log
                $this->logUsage('CREATE', $this->request->data['database_name'], $this->request->data['owner']);
                
                $this->Flash->success(__('Your database [{0}] has been queued for creation. You will receive an email when the operation is complete.', h($this->request->data['database_name'])));
                return $this->redirect('/dbs');
            }
            $this->Flash->error(__('Unable to add your db.'));
        }
        $this->set('db', $db);
    }

    public function edit($id = null)
    {
        $db = $this->Dbs->get($id);
        if ($this->request->is(['post', 'put'])) {
            $this->Dbs->patchEntity($db, $this->request->data);
            if ($this->Dbs->save($db)) {
                $this->Flash->success(__('Your db has been updated.'));
                return $this->redirect('/dbs');
            }
            $this->Flash->error(__('Unable to update your db.'));
        }

        $this->set('db', $db);
    }

    public function delete($id)
    {
        $this->request->allowMethod(['post', 'delete']);

        $db = $this->Dbs->get($id);
        //log this into the fifo queue table to be processed
        $this->logDBCreateOrDelete('DELETE', $db['database_name'], strtolower($_SERVER['AUTH_USER']));
        //log this action into our usage log
        $this->logUsage('DELETE', $db['database_name'], strtolower($_SERVER['AUTH_USER']));
        if ($this->Dbs->delete($db)) {
             $this->Flash->success(__('The database [{0}] has been queued for deletion. You will receive an email when the operation is complete.', h($db['database_name'])));
             return $this->redirect('/dbs');
        }
    }
}

?>